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
const FILLED_MONEY_TRAY_TEXTURE := preload("res://assets/sprites/ui/sukli/sized/money_tray_filled.png")
const LISTAHAN_PAPER_TEXTURE := preload("res://assets/sprites/ui/sukli/sized/listahan_note.png")
const COUNTER_PANEL_TEXTURE := preload("res://assets/sprites/ui/sukli/sized/counter_paper.png")
const WOODEN_TAG_TEXTURE := preload("res://assets/sprites/ui/sukli/sized/wooden_tag.png")
const IBIGAY_BUTTON_TEXTURE := preload("res://assets/sprites/ui/sukli/sized/ibigay_button.png")
const LINISIN_BUTTON_TEXTURE := preload("res://assets/sprites/ui/sukli/sized/linisin_button.png")
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
const PANEL_RIM_THICKNESS := 18.0
const CONTENT_PADDING := 24.0
const CONTENT_GAP := 21.0
const TRAY_VERTICAL_GAP := 21.0
const TRAY_SCALE := 0.95
const NOTE_UNGUIDED_HEIGHT_RATIO := 0.30
const NOTE_GUIDED_EXTRA_HEIGHT := 36.0
const HELPER_AMBER := Color("#8b4f19")
const HELPER_RED := Color("#992f25")
const TRAY_COMPARTMENT_BOUNDS := [Vector2(0.0, 0.1419), Vector2(0.1419, 0.2724), Vector2(0.2724, 0.4010), Vector2(0.4010, 0.6629), Vector2(0.6629, 1.0)]
const FILLED_TRAY_TEXTURE_ASPECT_RATIO := 1050.0 / 176.0

# Counter chips: the money the player has already placed on the counter.
# Heights/widths are in "unit" space (multiplied by _unit at runtime).
const CHIP_MAX_HEIGHT := 76.0
const CHIP_MIN_HEIGHT := 40.0
const CHIP_COIN_WIDTH_RATIO := 1.1
const CHIP_BILL_WIDTH_RATIO := 1.55
const CHIP_ICON_PADDING := 7.0
const CHIP_BADGE_SIZE := Vector2(44.0, 28.0)
const STATUS_COLUMN_WIDTH := 210.0
const COUNTER_EMPTY_TEXT := "ILAGAY DITO ANG SUKLI"

var customer_id: String = ""
var _pile: Array[int] = []
var _open := false
var _guide_enabled := false
var _change_due := 0
var _font: Font
var _panel: PanelContainer
var _drawer_position := Vector2.ZERO
var _drawer_size := Vector2.ZERO
var _content_box := Rect2()
var _top_row_height := 0.0
var _tray_display_size := Vector2.ZERO
var _unit := 1.0
var _bayad_label: Label
var _total_label: Label
var _due_label: Label
var _list_change_row: HBoxContainer
var _list_rule: HSeparator
var _list_rows: VBoxContainer
var _list_spacers: Array[Control] = []
var _note_paper: NinePatchRect
var _counter_total_label: Label
var _counter_status: VBoxContainer
var _counter_flow: HFlowContainer
var _counter_empty_label: Label
var _chip_height := 72.0
var _pop_value := -1
var _progress_bar: TextureProgressBar
var _helper_row: HBoxContainer
var _helper_prefix: Label
var _helper_amount: Label
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
	_configure_content_box()
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
	_note_paper.size.y = _top_row_height + NOTE_GUIDED_EXTRA_HEIGHT if _guide_enabled else _drawer_size.y * NOTE_UNGUIDED_HEIGHT_RATIO
	for index in _list_spacers.size():
		_list_spacers[index].visible = _guide_enabled or index < 2
	_progress_bar.visible = _guide_enabled
	_helper_row.visible = _guide_enabled
	# Without the guide there is no bar/helper text, so the chips get the full width.
	_counter_status.visible = _guide_enabled
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


func _configure_content_box() -> void:
	var inner_origin := Vector2(PANEL_RIM_THICKNESS, PANEL_RIM_THICKNESS)
	var inner_size := _drawer_size - Vector2(PANEL_RIM_THICKNESS * 2.0, PANEL_RIM_THICKNESS * 2.0)
	_content_box = Rect2(inner_origin + Vector2(CONTENT_PADDING, CONTENT_PADDING), inner_size - Vector2(CONTENT_PADDING * 2.0, CONTENT_PADDING * 2.0))
	var tray_width := _drawer_size.x * 0.70 * TRAY_SCALE
	_tray_display_size = Vector2(tray_width, tray_width / FILLED_TRAY_TEXTURE_ASPECT_RATIO)
	_top_row_height = _content_box.size.y - _tray_display_size.y - TRAY_VERTICAL_GAP


func _build_listahan_note(canvas: Control) -> void:
	_note_paper = _art_patch(LISTAHAN_PAPER_TEXTURE, "ListahanPaper", 10, 10)
	_note_paper.position = _content_box.position
	_note_paper.size = Vector2(_drawer_size.x * 0.215, _top_row_height + NOTE_GUIDED_EXTRA_HEIGHT)
	_note_paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(_note_paper)
	var content := MarginContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, false)
	content.add_theme_constant_override("margin_left", int(_unit * 21.0))
	content.add_theme_constant_override("margin_right", int(_unit * 21.0))
	content.add_theme_constant_override("margin_top", int(_unit * 18.0))
	content.add_theme_constant_override("margin_bottom", int(_unit * 21.0))
	_note_paper.add_child(content)
	_list_rows = VBoxContainer.new()
	_list_rows.add_theme_constant_override("separation", 0)
	content.add_child(_list_rows)
	var title_holder := CenterContainer.new()
	title_holder.custom_minimum_size = Vector2(0.0, _unit * 17.0)
	var tag := _wood_tag("LISTAHAN", "ListahanTag", int(21.0 * _unit), GOLD, INK)
	tag.custom_minimum_size = Vector2(_note_paper.size.x * 0.63, _unit * 17.0)
	title_holder.add_child(tag)
	_list_rows.add_child(title_holder)
	_list_rows.add_child(_list_spacer(_unit * 8.0))
	_bayad_label = _money_row(_list_rows, "BAYAD", "ListahanBayadValue", int(21.0 * _unit), INK, _unit * 25.0)
	_list_rows.add_child(_list_spacer(_unit * 4.0))
	_total_label = _money_row(_list_rows, "BILI", "ListahanBiliValue", int(21.0 * _unit), INK, _unit * 25.0)
	_list_rows.add_child(_list_spacer(_unit * 6.0))
	_list_rule = HSeparator.new()
	_list_rule.custom_minimum_size = Vector2(0.0, _unit * 3.0)
	_list_rule.add_theme_stylebox_override("separator", _dashed_rule())
	_list_rows.add_child(_list_rule)
	_list_rows.add_child(_list_spacer(_unit * 3.0))
	_list_change_row = HBoxContainer.new()
	_list_change_row.custom_minimum_size = Vector2(0.0, _unit * 45.0)
	var change_label := _label("SUKLI", int(21.0 * _unit), INK)
	change_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	change_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_list_change_row.add_child(change_label)
	_due_label = _label("", int(30.0 * _unit), GREEN)
	_due_label.name = "ListahanSukliValue"
	_due_label.custom_minimum_size = Vector2(_unit * 90.0, 0.0)
	_due_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_due_label.clip_text = false
	_due_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_due_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_list_change_row.add_child(_due_label)
	_list_rows.add_child(_list_change_row)


func _list_spacer(height: float) -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, height)
	_list_spacers.append(spacer)
	return spacer


# Layout of the "NASA COUNTER" parchment:
#
#   NASA COUNTER                                  P35 / P73     <- headline
#   [slim progress bar ]   +---------------------------------+
#   [ Kulang pa P38    ]   | [P20] [P10] [P5 x2]  (big chips)|  <- body
#                          +---------------------------------+
#
# The old layout stacked everything vertically, which left only ~27 units of
# height for the chips. Splitting the body into a status column (left) and a
# chip "well" (right) lets the chips use the full body height instead.
func _build_counter_tray(canvas: Control) -> void:
	var tray := _art_patch(COUNTER_PANEL_TEXTURE, "CounterPanelArt", 10, 10)
	var note_width := _note_paper.size.x
	var actions_width := _drawer_size.x * 0.16
	tray.position = Vector2(_content_box.position.x + note_width + CONTENT_GAP, _content_box.position.y)
	tray.size = Vector2(_content_box.end.x - actions_width - CONTENT_GAP - tray.position.x, _top_row_height)
	tray.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(tray)
	# Whatever height is left after margins, headline and well padding goes to the chips.
	_chip_height = clampf(_top_row_height - _unit * 76.0, _unit * CHIP_MIN_HEIGHT, _unit * CHIP_MAX_HEIGHT)
	var content := MarginContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, false)
	content.add_theme_constant_override("margin_left", int(_unit * 15.0))
	content.add_theme_constant_override("margin_right", int(_unit * 26.0))
	content.add_theme_constant_override("margin_top", int(_unit * 15.0))
	content.add_theme_constant_override("margin_bottom", int(_unit * 15.0))
	tray.add_child(content)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 0)
	content.add_child(rows)
	var headline := HBoxContainer.new()
	headline.custom_minimum_size = Vector2(0.0, _unit * 30.0)
	rows.add_child(headline)
	var heading := _label("NASA COUNTER", int(22.0 * _unit), INK)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	headline.add_child(heading)
	_counter_total_label = _label("P0", int(30.0 * _unit), INK)
	_counter_total_label.name = "CounterReadout"
	_counter_total_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_counter_total_label.size_flags_horizontal = Control.SIZE_SHRINK_END
	headline.add_child(_counter_total_label)

	var body := HBoxContainer.new()
	body.name = "CounterBody"
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", int(_unit * 14.0))
	rows.add_child(body)

	# Left: progress bar + helper text (guide mode only).
	_counter_status = VBoxContainer.new()
	_counter_status.name = "CounterStatus"
	_counter_status.custom_minimum_size = Vector2(_unit * STATUS_COLUMN_WIDTH, 0.0)
	_counter_status.alignment = BoxContainer.ALIGNMENT_CENTER
	_counter_status.add_theme_constant_override("separation", int(_unit * 6.0))
	body.add_child(_counter_status)
	var progress_slot := Control.new()
	progress_slot.custom_minimum_size = Vector2(0.0, _unit * 21.0)
	_counter_status.add_child(progress_slot)
	_progress_bar = TextureProgressBar.new()
	_progress_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, false)
	_progress_bar.min_value = 0.0
	_progress_bar.texture_under = PROGRESS_TRACK_TEXTURE
	_progress_bar.texture_progress = PROGRESS_FILL_TEXTURE
	_progress_bar.nine_patch_stretch = true
	progress_slot.add_child(_progress_bar)
	var helper_slot := CenterContainer.new()
	helper_slot.custom_minimum_size = Vector2(0.0, _unit * 30.0)
	_counter_status.add_child(helper_slot)
	_helper_row = HBoxContainer.new()
	_helper_row.name = "CounterHelperRow"
	_helper_row.add_theme_constant_override("separation", int(_unit * 4.0))
	helper_slot.add_child(_helper_row)
	_helper_prefix = _label("", int(26.0 * _unit), HELPER_AMBER)
	_helper_prefix.name = "CounterHelperPrefix"
	_helper_prefix.add_theme_constant_override("outline_size", 1)
	_helper_prefix.add_theme_color_override("font_outline_color", HELPER_AMBER)
	_helper_row.add_child(_helper_prefix)
	_helper_amount = _label("", int(30.0 * _unit), HELPER_AMBER)
	_helper_amount.name = "CounterHelperAmount"
	_helper_amount.add_theme_constant_override("outline_size", 1)
	_helper_amount.add_theme_color_override("font_outline_color", HELPER_AMBER)
	_helper_row.add_child(_helper_amount)

	# Right: the counter "well" that holds the placed money.
	var well := PanelContainer.new()
	well.name = "CounterWell"
	well.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	well.size_flags_vertical = Control.SIZE_EXPAND_FILL
	well.mouse_filter = Control.MOUSE_FILTER_IGNORE
	well.add_theme_stylebox_override("panel", _well_box())
	body.add_child(well)
	_counter_flow = HFlowContainer.new()
	_counter_flow.name = "CounterChipRow"
	_counter_flow.add_theme_constant_override("h_separation", int(_unit * 10.0))
	_counter_flow.add_theme_constant_override("v_separation", int(_unit * 6.0))
	well.add_child(_counter_flow)
	_counter_empty_label = _label(COUNTER_EMPTY_TEXT, int(22.0 * _unit), Color(INK, 0.4))
	_counter_empty_label.name = "CounterEmptyHint"
	_counter_empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_counter_empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	well.add_child(_counter_empty_label)


func _build_drawer_slots(canvas: Control) -> void:
	var drawer := _texture_rect(FILLED_MONEY_TRAY_TEXTURE, "MoneyTrayArt")
	drawer.position = _content_box.end - _tray_display_size
	drawer.size = _tray_display_size
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
	coin_tag.anchor_bottom = 0.0
	coin_tag.offset_left = 0.0
	coin_tag.offset_right = 0.0
	coin_tag.offset_top = -TRAY_VERTICAL_GAP + _unit * 0.5
	coin_tag.offset_bottom = -_unit * 0.5
	group_tags.add_child(coin_tag)
	var bill_tag := _wood_tag("PERA", "PeraTag", int(20.0 * _unit), WOOD, PAPER)
	bill_tag.anchor_left = 0.65
	bill_tag.anchor_right = 0.77
	bill_tag.anchor_top = 0.0
	bill_tag.anchor_bottom = 0.0
	bill_tag.offset_top = -TRAY_VERTICAL_GAP + _unit * 0.5
	bill_tag.offset_bottom = -_unit * 0.5
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
		var slot := _drawer_slot(value, drawer.size.x * (bounds.y - bounds.x))
		slot.anchor_left = bounds.x
		slot.anchor_right = bounds.y
		slot.anchor_top = 0.0
		slot.anchor_bottom = 1.0
		slot.pressed.connect(_on_denomination_tapped.bind(value, slot))
		slots.add_child(slot)


func _build_actions(canvas: Control) -> void:
	var actions := VBoxContainer.new()
	actions.name = "SukliActions"
	actions.position = Vector2(_content_box.end.x - _drawer_size.x * 0.16, _content_box.position.y)
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
	_msg_label.position = actions.position + Vector2(_unit * 3.0, actions.size.y + _unit * 4.0)
	_msg_label.size = Vector2(actions.size.x - _unit * 3.0, _drawer_size.y * 0.03)
	canvas.add_child(_msg_label)


func _drawer_slot(value: int, slot_width: float) -> Button:
	var button := _button("", int(16.0 * _unit), Color.TRANSPARENT)
	button.custom_minimum_size = Vector2(slot_width, _drawer_size.y * 0.32)
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	
	# FIX: Prevent Button node from reacting twice to mobile touches
	button.gui_input.connect(func(event: InputEvent):
		if event is InputEventScreenTouch:
			button.accept_event()
	)
	
	var feedback := ColorRect.new()
	feedback.name = "TapFeedback"
	feedback.color = Color(1.0, 0.87, 0.35, 0.0)
	feedback.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, false)
	feedback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(feedback)
	return button


func _on_denomination_tapped(value: int, slot: Button) -> void:
	var feedback := slot.get_node_or_null("TapFeedback") as ColorRect
	if feedback:
		var feedback_tween := create_tween()
		feedback_tween.tween_property(feedback, "color:a", 0.18, 0.04)
		feedback_tween.tween_property(feedback, "color:a", 0.0, 0.04)
	_pile.append(value)
	# Remember which chip changed so only that chip plays the "pop" animation.
	_pop_value = value
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
		# Detach first so the flow container does not lay out the dying chips
		# alongside the new ones for a frame.
		_counter_flow.remove_child(child)
		child.queue_free()
	var total := 0
	for value in _pile:
		total += value
	# Same left-to-right order as the tray (P1 -> P50), so each chip sits in the
	# same relative position as the slot it came from.
	for value in SukliRules.DENOMINATIONS:
		var count := _pile.count(value)
		if count > 0:
			var piece := _counter_piece(value, count)
			_counter_flow.add_child(piece)
			if value == _pop_value:
				_pop(piece.get_node("Content") as Control)
	_pop_value = -1
	_counter_empty_label.visible = _pile.is_empty()
	if _guide_enabled:
		_counter_total_label.text = "%s / %s" % [_money_text(total), _money_text(_change_due)]
		_progress_bar.max_value = maxf(1.0, float(_change_due))
		_progress_bar.value = minf(float(total), float(_change_due))
		if total < _change_due:
			_progress_bar.tint_progress = Color.WHITE
			_set_helper("Kulang pa", _money_text(_change_due - total), HELPER_AMBER)
		elif total == _change_due:
			_progress_bar.tint_progress = GREEN
			_set_helper("Eksakto!", "", GREEN)
		else:
			_progress_bar.tint_progress = RED
			_set_helper("Sobra ng", _money_text(total - _change_due), HELPER_RED)
	else:
		_counter_total_label.text = _money_text(total)
	_counter_total_label.pivot_offset = _counter_total_label.size * 0.5
	_counter_total_label.scale = Vector2(1.08, 1.08)
	create_tween().tween_property(_counter_total_label, "scale", Vector2.ONE, 0.12)


func _set_helper(prefix: String, amount: String, color: Color) -> void:
	_helper_prefix.text = prefix
	_helper_prefix.add_theme_color_override("font_color", color)
	_helper_prefix.add_theme_color_override("font_outline_color", color)
	_helper_amount.text = amount
	_helper_amount.visible = not amount.is_empty()
	_helper_amount.add_theme_color_override("font_color", color)
	_helper_amount.add_theme_color_override("font_outline_color", color)


func _is_bill(value: int) -> bool:
	return value >= 20


# One chip = one denomination currently on the counter. Tapping it removes one.
# Coins are near-square, bills are wide, so the shape alone tells them apart.
# The count only shows as a badge when there is more than one.
func _counter_piece(value: int, count: int) -> Button:
	var width_ratio := CHIP_BILL_WIDTH_RATIO if _is_bill(value) else CHIP_COIN_WIDTH_RATIO
	var chip_size := Vector2(_chip_height * width_ratio, _chip_height)
	var piece := _button("", int(16.0 * _unit), PAPER)
	piece.name = "CounterPiece%d" % value
	piece.custom_minimum_size = chip_size
	piece.add_theme_stylebox_override("normal", _chip_box(PAPER))
	piece.add_theme_stylebox_override("hover", _chip_box(PAPER.lightened(0.1)))
	piece.add_theme_stylebox_override("pressed", _chip_box(PAPER_DARK))
	
	piece.gui_input.connect(func(event: InputEvent):
		if event is InputEventScreenTouch:
			piece.accept_event()
	)
	# Everything visual lives under "Content", because the container owns the
	# chip's own scale. Animating Content avoids the container resetting it.
	var content := Control.new()
	content.name = "Content"
	content.size = chip_size
	content.pivot_offset = chip_size * 0.5
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	piece.add_child(content)
	var pad := _unit * CHIP_ICON_PADDING
	var icon := _money_texture_rect(_money_texture(value), "CounterMoney%d" % value)
	icon.position = Vector2(pad, pad)
	icon.size = chip_size - Vector2(pad, pad) * 2.0
	content.add_child(icon)
	if count > 1:
		var badge_size := CHIP_BADGE_SIZE * _unit
		var badge := PanelContainer.new()
		badge.name = "CountBadge"
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.add_theme_stylebox_override("panel", _badge_box())
		badge.custom_minimum_size = badge_size
		badge.size = badge_size
		badge.position = Vector2(chip_size.x - badge_size.x + _unit * 6.0, -_unit * 6.0)
		var badge_label := _label("x%d" % count, int(20.0 * _unit), PAPER)
		badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge.add_child(badge_label)
		content.add_child(badge)
	piece.pressed.connect(_remove_one_of.bind(value))
	return piece


# Quick scale "pop" so the player sees which chip just changed.
func _pop(node: Control) -> void:
	if node == null:
		return
	var tween := node.create_tween()
	tween.tween_property(node, "scale", Vector2(1.18, 1.18), 0.07).from(Vector2(0.75, 0.75)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "scale", Vector2.ONE, 0.09)


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


func _money_row(parent: VBoxContainer, label_text: String, value_name: String, font_size: int, color: Color, row_height: float) -> Label:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0.0, row_height)
	var label := _label(label_text, font_size, color)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_text = false
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var value := _label("", font_size, color)
	value.name = value_name
	value.autowrap_mode = TextServer.AUTOWRAP_OFF
	value.clip_text = false
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
	
	# FIX: Keep action buttons from executing twice on mobile devices
	button.gui_input.connect(func(event: InputEvent):
		if event is InputEventScreenTouch:
			button.accept_event()
	)
	
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


# Slightly darker, soft-bordered inset so the placed money reads as "on the counter".
func _well_box() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(PAPER_DARK, 0.55)
	box.border_color = Color(INK, 0.35)
	box.set_border_width_all(int(_unit * 3.0))
	box.set_corner_radius_all(6)
	box.anti_aliasing = false
	box.set_content_margin_all(_unit * 6.0)
	return box


# Thinner border than _box() (which uses BORDER_W = 6) so the money art gets the room.
func _chip_box(bg: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = INK
	box.set_border_width_all(int(_unit * 4.0))
	box.set_corner_radius_all(6)
	box.anti_aliasing = false
	return box


func _badge_box() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = INK
	box.border_color = PAPER
	box.set_border_width_all(int(_unit * 2.0))
	box.set_corner_radius_all(int(_unit * 14.0))
	box.anti_aliasing = false
	box.set_content_margin_all(0.0)
	return box


func _dashed_rule() -> StyleBoxFlat:
	var rule := StyleBoxFlat.new()
	rule.bg_color = Color(INK, 0.45)
	rule.content_margin_left = _unit * 4.0
	rule.content_margin_right = _unit * 4.0
	return rule
