class_name CashTray
extends Control

# The tall Sukli drawer mirrors the full cashier-panel reference while leaving the window visible.

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
const PESO := "₱"
const DRAWER_FRAME_TEXTURE := preload("res://assets/sprites/ui/sukli/sized/walnut_panel_background.png")
const MONEY_TRAY_TEXTURE := preload("res://assets/sprites/ui/sukli/sized/money_tray.png")
const LISTAHAN_PAPER_TEXTURE := preload("res://assets/sprites/ui/sukli/sized/listahan_note.png")
const COUNTER_PANEL_TEXTURE := preload("res://assets/sprites/ui/sukli/sized/counter_paper.png")
const WOODEN_TAG_TEXTURE := preload("res://assets/sprites/ui/sukli/sized/wooden_tag.png")
const IBIGAY_BUTTON_TEXTURE := preload("res://assets/sprites/ui/sukli/sized/ibigay_button.png")
const LINISIN_BUTTON_TEXTURE := preload("res://assets/sprites/ui/sukli/sized/linisin_button.png")
const CLOSE_BUTTON_TEXTURE := preload("res://assets/sprites/ui/sukli/sized/close_button.png")
const PROGRESS_TRACK_TEXTURE := preload("res://assets/sprites/ui/sukli/sized/progress_track.png")
const PROGRESS_FILL_TEXTURE := preload("res://assets/sprites/ui/sukli/sized/progress_fill.png")
const MONEY_TEXTURES := {
	1: preload("res://assets/sprites/ui/sukli/sized/coin_1.png"),
	5: preload("res://assets/sprites/ui/sukli/sized/coin_5.png"),
	10: preload("res://assets/sprites/ui/sukli/sized/coin_10.png"),
	20: preload("res://assets/sprites/ui/sukli/sized/bill_20.png"),
	50: preload("res://assets/sprites/ui/sukli/sized/bill_50.png"),
}
const BORDER_W := 6
const CORNER := 12
const SUKLI_PANEL_WIDTH_RATIO := 1000.0 / 1280.0
const SUKLI_PANEL_HEIGHT_RATIO := 280.0 / 720.0
const SUKLI_PANEL_BOTTOM_MARGIN_RATIO := 6.0 / 720.0
const TRAY_COMPARTMENT_BOUNDS := [Vector2(0.02, 0.138), Vector2(0.148, 0.270), Vector2(0.280, 0.402), Vector2(0.414, 0.658), Vector2(0.672, 0.972)]
const TRAY_FLOOR_TOP_RATIO := 0.24
const TRAY_FLOOR_BOTTOM_RATIO := 0.81
const TRAY_TEXTURE_ASPECT_RATIO := 1020.0 / 166.0

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
var _list_change_row: HBoxContainer
var _list_rule: HSeparator
var _list_rows: VBoxContainer
var _list_top_spacer: Control
var _list_bottom_spacer: Control
var _counter_total_label: Label
var _counter_flow: HFlowContainer
var _progress_bar: TextureProgressBar
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
	_drawer_size = Vector2(StorefrontLayout.VIEWPORT_SIZE.x * SUKLI_PANEL_WIDTH_RATIO, StorefrontLayout.VIEWPORT_SIZE.y * SUKLI_PANEL_HEIGHT_RATIO)
	_drawer_position = Vector2((StorefrontLayout.VIEWPORT_SIZE.x - _drawer_size.x) * 0.5, StorefrontLayout.VIEWPORT_SIZE.y - _drawer_size.y - StorefrontLayout.VIEWPORT_SIZE.y * SUKLI_PANEL_BOTTOM_MARGIN_RATIO)
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = _drawer_size
	_panel.size = _drawer_size
	_panel.position = _drawer_position + Vector2(0.0, _drawer_size.y)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
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
	_bayad_label.text = _money_text(customer.payment.tendered)
	_total_label.text = _money_text(customer.payment.total)
	_due_label.text = _money_text(_change_due)
	_due_label.visible = _guide_enabled
	_list_change_row.visible = _guide_enabled
	_list_rule.visible = _guide_enabled
	_list_rows.alignment = BoxContainer.ALIGNMENT_BEGIN
	_list_top_spacer.visible = not _guide_enabled
	_list_bottom_spacer.visible = true
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
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, false)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var frame := _art_patch(DRAWER_FRAME_TEXTURE, "DrawerFrameArt", 18, 18)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, false)
	_panel.add_child(frame)
	_panel.add_child(canvas)
	_build_listahan_note(canvas)
	_build_counter_tray(canvas)
	_build_drawer_slots(canvas)
	_build_actions(canvas)
	_build_close_button(canvas)


func _build_listahan_note(canvas: Control) -> void:
	var note := _art_patch(LISTAHAN_PAPER_TEXTURE, "ListahanPaper", 10, 10)
	note.position = Vector2(_drawer_size.x * 0.04, _drawer_size.y * 0.055)
	note.size = Vector2(_drawer_size.x * 0.215, _drawer_size.y * 0.39)
	note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(note)
	var content := MarginContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, false)
	content.add_theme_constant_override("margin_left", int(_unit * 15.0))
	content.add_theme_constant_override("margin_right", int(_unit * 15.0))
	content.add_theme_constant_override("margin_top", int(_unit * 10.0))
	content.add_theme_constant_override("margin_bottom", int(_unit * 10.0))
	note.add_child(content)
	_list_rows = VBoxContainer.new()
	_list_rows.alignment = BoxContainer.ALIGNMENT_BEGIN
	_list_rows.add_theme_constant_override("separation", int(_unit * 5.0))
	content.add_child(_list_rows)
	var title_holder := CenterContainer.new()
	title_holder.custom_minimum_size = Vector2(0.0, _unit * 24.0)
	var tag := _wood_tag("LISTAHAN", "ListahanTag", int(21.0 * _unit), GOLD, INK)
	tag.custom_minimum_size = Vector2(note.size.x * 0.63, _unit * 24.0)
	title_holder.add_child(tag)
	_list_rows.add_child(title_holder)
	_list_top_spacer = Control.new()
	_list_top_spacer.name = "ListahanTopSpacer"
	_list_top_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list_top_spacer.visible = false
	_list_rows.add_child(_list_top_spacer)
	_bayad_label = _money_row(_list_rows, "BAYAD", "ListahanBayadValue", int(24.0 * _unit), INK)
	_total_label = _money_row(_list_rows, "BILI", "ListahanBiliValue", int(24.0 * _unit), INK)
	_list_bottom_spacer = Control.new()
	_list_bottom_spacer.name = "ListahanBottomSpacer"
	_list_bottom_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list_rows.add_child(_list_bottom_spacer)
	_list_rule = HSeparator.new()
	_list_rule.custom_minimum_size = Vector2(0.0, _unit * 4.0)
	_list_rule.add_theme_stylebox_override("separator", _dashed_rule())
	_list_rows.add_child(_list_rule)
	_list_change_row = HBoxContainer.new()
	_list_change_row.custom_minimum_size = Vector2(0.0, _unit * 36.0)
	var change_label := _label("SUKLI", int(21.0 * _unit), INK)
	change_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_change_row.add_child(change_label)
	_due_label = _label("", int(36.0 * _unit), GREEN)
	_due_label.name = "ListahanSukliValue"
	_due_label.custom_minimum_size = Vector2(_unit * 90.0, 0.0)
	_due_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_due_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_due_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_list_change_row.add_child(_due_label)
	_list_rows.add_child(_list_change_row)


func _build_counter_tray(canvas: Control) -> void:
	var tray := _art_patch(COUNTER_PANEL_TEXTURE, "CounterPanelArt", 10, 10)
	tray.position = Vector2(_drawer_size.x * 0.28, _drawer_size.y * 0.055)
	tray.size = Vector2(_drawer_size.x * 0.45, _drawer_size.y * 0.39)
	tray.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(tray)
	var content := MarginContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, false)
	content.add_theme_constant_override("margin_left", int(_unit * 15.0))
	content.add_theme_constant_override("margin_right", int(_unit * 15.0))
	content.add_theme_constant_override("margin_top", int(_unit * 10.0))
	content.add_theme_constant_override("margin_bottom", int(_unit * 10.0))
	tray.add_child(content)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", int(_unit * 5.0))
	content.add_child(rows)
	var headline := HBoxContainer.new()
	headline.custom_minimum_size = Vector2(0.0, _unit * 24.0)
	rows.add_child(headline)
	var heading := _label("NASA COUNTER", int(22.0 * _unit), INK)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	headline.add_child(heading)
	_counter_total_label = _label("P0", int(36.0 * _unit), INK)
	_counter_total_label.name = "CounterReadout"
	_counter_total_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_counter_total_label.size_flags_horizontal = Control.SIZE_SHRINK_END
	headline.add_child(_counter_total_label)
	_progress_bar = TextureProgressBar.new()
	_progress_bar.min_value = 0.0
	_progress_bar.custom_minimum_size = Vector2(0.0, _unit * 24.0)
	_progress_bar.texture_under = PROGRESS_TRACK_TEXTURE
	_progress_bar.texture_progress = PROGRESS_FILL_TEXTURE
	_progress_bar.nine_patch_stretch = true
	rows.add_child(_progress_bar)
	_helper_label = _label("", int(18.0 * _unit), INK)
	_helper_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_helper_label.custom_minimum_size = Vector2(0.0, _unit * 18.0)
	rows.add_child(_helper_label)
	_counter_flow = HFlowContainer.new()
	_counter_flow.add_theme_constant_override("h_separation", int(_unit * 8.0))
	_counter_flow.add_theme_constant_override("v_separation", int(_unit * 6.0))
	_counter_flow.custom_minimum_size = Vector2(0.0, _unit * 40.0)
	rows.add_child(_counter_flow)


func _build_drawer_slots(canvas: Control) -> void:
	var drawer := _texture_rect(MONEY_TRAY_TEXTURE, "MoneyTrayArt")
	var tray_width := _drawer_size.x * 0.71
	var tray_height := tray_width / TRAY_TEXTURE_ASPECT_RATIO
	drawer.position = Vector2(_drawer_size.x * 0.28, _drawer_size.y * 0.48)
	drawer.size = Vector2(tray_width, tray_height)
	drawer.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	canvas.add_child(drawer)
	var group_tags := Control.new()
	group_tags.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, false)
	drawer.add_child(group_tags)
	var coin_tag := _wood_tag("BARYA", "BaryaTag", int(20.0 * _unit), WOOD, PAPER)
	coin_tag.set_anchors_preset(Control.PRESET_CENTER_TOP, false)
	coin_tag.anchor_left = 0.15
	coin_tag.anchor_right = 0.27
	coin_tag.anchor_top = 0.0
	coin_tag.anchor_bottom = 0.16
	coin_tag.offset_left = 0.0
	coin_tag.offset_right = 0.0
	coin_tag.offset_top = 0.0
	coin_tag.offset_bottom = 0.0
	group_tags.add_child(coin_tag)
	var bill_tag := _wood_tag("PERA", "PeraTag", int(20.0 * _unit), WOOD, PAPER)
	bill_tag.anchor_left = 0.65
	bill_tag.anchor_right = 0.77
	bill_tag.anchor_top = 0.0
	bill_tag.anchor_bottom = 0.16
	group_tags.add_child(bill_tag)
	var slots := Control.new()
	slots.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, false)
	drawer.add_child(slots)
	var coin_group_center := (TRAY_COMPARTMENT_BOUNDS[0].x + TRAY_COMPARTMENT_BOUNDS[2].y) * 0.5
	var bill_group_center := (TRAY_COMPARTMENT_BOUNDS[3].x + TRAY_COMPARTMENT_BOUNDS[4].y) * 0.5
	var tag_width_ratio := 0.12
	coin_tag.anchor_left = coin_group_center - tag_width_ratio * 0.5
	coin_tag.anchor_right = coin_group_center + tag_width_ratio * 0.5
	bill_tag.anchor_left = bill_group_center - tag_width_ratio * 0.5
	bill_tag.anchor_right = bill_group_center + tag_width_ratio * 0.5
	for index in SukliRules.DENOMINATIONS.size():
		var value: int = SukliRules.DENOMINATIONS[index]
		var bounds: Vector2 = TRAY_COMPARTMENT_BOUNDS[index]
		var slot := _drawer_slot(value, _drawer_size.x * (bounds.y - bounds.x))
		slot.anchor_left = bounds.x
		slot.anchor_right = bounds.y
		slot.anchor_top = TRAY_FLOOR_TOP_RATIO
		slot.anchor_bottom = TRAY_FLOOR_BOTTOM_RATIO
		slot.pressed.connect(_on_denomination_tapped.bind(value, slot))
		slots.add_child(slot)
	var front_lip := _texture_rect(_tray_front_lip_texture(), "MoneyTrayFrontLip")
	front_lip.anchor_top = TRAY_FLOOR_BOTTOM_RATIO
	front_lip.anchor_bottom = 1.0
	front_lip.anchor_left = 0.0
	front_lip.anchor_right = 1.0
	front_lip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drawer.add_child(front_lip)


func _build_actions(canvas: Control) -> void:
	var actions := VBoxContainer.new()
	actions.position = Vector2(_drawer_size.x * 0.76, _drawer_size.y * 0.055)
	actions.size = Vector2(_drawer_size.x * 0.16, _drawer_size.y * 0.35)
	actions.add_theme_constant_override("separation", int(_unit * 4.0))
	canvas.add_child(actions)
	_give_button = _art_button("IBIGAY", int(34.0 * _unit), IBIGAY_BUTTON_TEXTURE, 9, 9)
	_give_button.custom_minimum_size = Vector2(0.0, _unit * 69.0)
	_give_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_give_button.pressed.connect(_on_give_pressed)
	actions.add_child(_give_button)
	var clear_button := _art_button("LINISIN", int(22.0 * _unit), LINISIN_BUTTON_TEXTURE, 8, 8)
	clear_button.custom_minimum_size = Vector2(0.0, _unit * 66.0)
	clear_button.pressed.connect(_clear_pile)
	actions.add_child(clear_button)
	_msg_label = _label("", int(18.0 * _unit), PAPER)
	_msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_msg_label.position = Vector2(_drawer_size.x * 0.76, _drawer_size.y * 0.397)
	_msg_label.size = Vector2(_drawer_size.x * 0.16, _drawer_size.y * 0.03)
	canvas.add_child(_msg_label)


func _build_close_button(canvas: Control) -> void:
	var close_button := _art_button("X", int(24.0 * _unit), CLOSE_BUTTON_TEXTURE, 7, 7)
	close_button.position = Vector2(_drawer_size.x * 0.94, _drawer_size.y * 0.055)
	close_button.size = Vector2(_unit * 51.0, _unit * 51.0)
	close_button.pressed.connect(close)
	canvas.add_child(close_button)


func _drawer_slot(value: int, slot_width: float) -> Button:
	var button := _button("", int(16.0 * _unit), Color.TRANSPARENT)
	button.custom_minimum_size = Vector2(maxf(_unit * 90.0, slot_width - _unit * 3.0), _drawer_size.y * 0.32)
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	var icon := _money_texture_rect(_money_texture(value), "Money%d" % value)
	icon.anchor_left = 0.125
	icon.anchor_top = 0.375
	icon.anchor_right = 0.875
	icon.anchor_bottom = 1.075
	var money_caption := _label(_money_text(value), int(21.0 * _unit), INK)
	money_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	money_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	money_caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, false)
	icon.add_child(money_caption)
	button.add_child(icon)
	return button


func _on_denomination_tapped(value: int, slot: Button) -> void:
	slot.pivot_offset = slot.size * 0.5
	slot.scale = Vector2(0.92, 0.92)
	create_tween().tween_property(slot, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
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
		_counter_total_label.text = "%s / %s" % [_money_text(total), _money_text(_change_due)]
		_progress_bar.max_value = maxf(1.0, float(_change_due))
		_progress_bar.value = minf(float(total), float(_change_due))
		if total < _change_due:
			_helper_label.text = "Kulang pa %s" % _money_text(_change_due - total)
		elif total == _change_due:
			_helper_label.text = "Eksakto!"
		else:
			_helper_label.text = "Sobra ng %s" % _money_text(total - _change_due)
	else:
		_counter_total_label.text = _money_text(total)
	_counter_total_label.pivot_offset = _counter_total_label.size * 0.5
	_counter_total_label.scale = Vector2(1.08, 1.08)
	create_tween().tween_property(_counter_total_label, "scale", Vector2.ONE, 0.12)


func _counter_piece(value: int, count: int) -> Button:
	var piece := _button("", int(16.0 * _unit), PAPER)
	piece.custom_minimum_size = Vector2(_drawer_size.x * 0.060, _drawer_size.y * 0.116)
	piece.add_theme_stylebox_override("normal", _box(PAPER, INK, _unit * 4.0, _unit * 2.0, 4))
	var icon := _money_texture_rect(_money_texture(value), "CounterMoney%d" % value)
	icon.position = Vector2(_unit * 6.0, _unit * 6.0)
	icon.size = Vector2(piece.custom_minimum_size.x * 0.52, piece.custom_minimum_size.y - _unit * 12.0)
	piece.add_child(icon)
	var badge := _label("x%d" % count, int(21.0 * _unit), INK)
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


func _money_text(value: int) -> String:
	return "%s%d" % [PESO, value]


func _money_row(parent: VBoxContainer, label_text: String, value_name: String, font_size: int, color: Color) -> Label:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0.0, _unit * 24.0)
	var label := _label(label_text, font_size, color)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var value := _label("", font_size, color)
	value.name = value_name
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value)
	parent.add_child(row)
	return value


func _wood_tag(text: String, node_name: String, font_size: int, background: Color, color: Color) -> PanelContainer:
	var tag := PanelContainer.new()
	tag.name = node_name
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var art := _art_patch(WOODEN_TAG_TEXTURE, "%sArt" % node_name, 6, 5)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, false)
	tag.add_child(art)
	var label := _label(text, font_size, color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tag.add_child(label)
	return tag


func _texture_rect(texture: Texture2D, node_name: String) -> TextureRect:
	var rect := TextureRect.new()
	rect.name = node_name
	rect.texture = texture
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


func _art_patch(texture: Texture2D, node_name: String, margin_x: int, margin_y: int) -> NinePatchRect:
	var patch := NinePatchRect.new()
	patch.name = node_name
	patch.texture = texture
	patch.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	patch.patch_margin_left = margin_x
	patch.patch_margin_right = margin_x
	patch.patch_margin_top = margin_y
	patch.patch_margin_bottom = margin_y
	patch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return patch


func _money_texture(value: int) -> Texture2D:
	return MONEY_TEXTURES.get(value) as Texture2D


func _tray_front_lip_texture() -> AtlasTexture:
	var front_lip := AtlasTexture.new()
	front_lip.atlas = MONEY_TRAY_TEXTURE
	front_lip.region = Rect2(0.0, MONEY_TRAY_TEXTURE.get_height() * TRAY_FLOOR_BOTTOM_RATIO, MONEY_TRAY_TEXTURE.get_width(), MONEY_TRAY_TEXTURE.get_height() * (1.0 - TRAY_FLOOR_BOTTOM_RATIO))
	return front_lip


func _money_texture_rect(texture: Texture2D, node_name: String) -> TextureRect:
	var rect := _texture_rect(texture, node_name)
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return rect


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


func _art_button(text: String, font_size: int, texture: Texture2D, margin_x: int, margin_y: int) -> Button:
	var button := _button(text, font_size, Color.TRANSPARENT)
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	var art := _art_patch(texture, "%sArt" % text.capitalize(), margin_x, margin_y)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, false)
	art.show_behind_parent = true
	button.add_child(art)
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
