class_name TrustTag
extends Control

# The Suki Meter: a paper tag hanging from the roof, like the DAY / TIME / CASH tags,
# with a chunky segmented bar (10 chunks) instead of a thin default ProgressBar.
# Call set_trust(value) whenever barangay trust changes. It animates itself.

const STRING_LEN := 16.0
const BODY_H := 84.0
const STRING_COLOR := Color("#6b4a2a")
const SEGMENTS := 10
const SEG_GAP := 3.0
const TRACK := Color("#422917")
const SEG_EMPTY := Color("#755537")
const GREEN := Color("#55bc53")
const YELLOW := Color("#e3bd39")
const RED := Color("#d94536")

var _target: float = 100.0
var _display: float = 100.0
var _bar: Control
var _title: Label
var _value_label: Label
var _value_tween: Tween
var _pulse_tween: Tween
var _warn_tween: Tween
var _sway_degrees: float = 0.0
var _sway_seconds: float = 3.0
var _hanging: bool = true

# hanging = true  -> the old paper tag on a string (sways).
# hanging = false -> a flat paper panel for the grouped HUD bar (no string, no hole, no sway).
func setup(initial_value: float, width: float, sway_degrees: float, sway_seconds: float, hanging: bool = true) -> TrustTag:
	_hanging = hanging
	var top := STRING_LEN if hanging else 0.0
	var body_h := BODY_H if hanging else 100.0
	size = Vector2(width, top + body_h)
	custom_minimum_size = size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	pivot_offset = Vector2(width * 0.5, 0.0) if hanging else size * 0.5
	_sway_degrees = sway_degrees
	_sway_seconds = sway_seconds
	_target = clampf(initial_value, 0.0, 100.0)
	_display = _target

	var body := PanelContainer.new()
	body.position = Vector2(0.0, top)
	body.size = Vector2(width, body_h)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# extra top margin so the text never runs into the punched hole
	var sb: StyleBox
	if hanging:
		sb = KwentaStyle.box(KwentaStyle.PAPER, KwentaStyle.INK, 16.0, 6.0, 18, 4, 6)
		# extra top margin so the text never runs into the punched hole
		sb.content_margin_top = 25.0
		sb.content_margin_bottom = 10.0
	else:
		sb = KwentaStyle.hud_frame("res://assets/sprites/ui/hud/suki_panel.png", 22.0, 16.0)   # cream HUD board
	body.add_theme_stylebox_override("panel", sb)
	add_child(body)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	if hanging:
		body.add_child(vbox)
	else:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 9)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		body.add_child(row)
		row.add_child(HudIcon.new().setup(HudIcon.Kind.HEART, 47.0, KwentaStyle.INK, Color("#e8483c")))
		row.add_child(vbox)

	var top_row := HBoxContainer.new()
	top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(top_row)

	var title_color: Color = KwentaStyle.INK_MUTED if hanging else KwentaStyle.INK
	var value_color: Color = KwentaStyle.INK
	_title = KwentaStyle.make_label("SUKI METER", 18 if hanging else 23, title_color)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(_title)

	_value_label = KwentaStyle.make_label(str(roundi(_display)), 22 if hanging else 27, value_color)
	_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top_row.add_child(_value_label)

	_bar = Control.new()
	_bar.custom_minimum_size = Vector2(width - 40.0 if hanging else width - 118.0, 28.0)
	_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar.draw.connect(_draw_bar)
	vbox.add_child(_bar)

	if hanging:
		# Punched hole with reinforcement ring, same as HudTag.
		var hole := Control.new()
		hole.size = size
		hole.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hole.draw.connect(_draw_hole.bind(hole))
		add_child(hole)
	queue_redraw()
	_refresh_warning()
	return self

func _ready() -> void:
	if _sway_degrees <= 0.0:
		return
	rotation_degrees = randf_range(-_sway_degrees, _sway_degrees)
	var sway := create_tween().set_loops()
	sway.tween_property(self, "rotation_degrees", _sway_degrees, _sway_seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	sway.tween_property(self, "rotation_degrees", -_sway_degrees, _sway_seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func set_trust(new_value: float) -> void:
	new_value = clampf(new_value, 0.0, 100.0)
	var dropped := _target - new_value >= 5.0    # small drips (slow drain) don't shake the tag
	var gained := new_value - _target >= 5.0
	_target = new_value

	if _value_tween != null and _value_tween.is_valid():
		_value_tween.kill()
	_value_tween = create_tween()
	_value_tween.tween_method(_set_display, _display, new_value, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_value_tween.tween_callback(_refresh_warning)

	if dropped:
		_pulse(Vector2(1.0, 1.0), Color(1.0, 0.55, 0.5))
	elif gained:
		_pulse(Vector2(1.07, 1.07), Color(0.85, 1.0, 0.85))

func _set_display(v: float) -> void:
	_display = v
	if _value_label != null:
		_value_label.text = str(roundi(v))
		if _hanging:
			_value_label.add_theme_color_override("font_color", _color_for(v).darkened(0.35))
	if _bar != null:
		_bar.queue_redraw()

func _color_for(v: float) -> Color:
	if v > 60.0:
		return GREEN
	if v > 30.0:
		return YELLOW
	return RED

func _pulse(pop_scale: Vector2, flash: Color) -> void:
	if _pulse_tween != null and _pulse_tween.is_valid():
		_pulse_tween.kill()
	scale = Vector2.ONE
	modulate = Color.WHITE
	_pulse_tween = create_tween().set_parallel(true)
	if pop_scale.x > 1.0:
		_pulse_tween.tween_property(self, "scale", pop_scale, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_pulse_tween.chain().tween_property(self, "scale", Vector2.ONE, 0.2)
	else:
		# a quick shake when trust drops
		var base_x := position.x
		var shake := create_tween()
		shake.tween_property(self, "position:x", base_x + 7.0, 0.04)
		shake.tween_property(self, "position:x", base_x - 7.0, 0.06)
		shake.tween_property(self, "position:x", base_x + 4.0, 0.05)
		shake.tween_property(self, "position:x", base_x, 0.05)
	modulate = flash
	_pulse_tween.tween_property(self, "modulate", Color.WHITE, 0.45)

func _refresh_warning() -> void:
	# Bar blinks softly while trust is in the red zone.
	if _warn_tween != null and _warn_tween.is_valid():
		_warn_tween.kill()
	if _bar == null:
		return
	_bar.modulate.a = 1.0
	if _target <= 30.0:
		_warn_tween = create_tween().set_loops()
		_warn_tween.tween_property(_bar, "modulate:a", 0.45, 0.35)
		_warn_tween.tween_property(_bar, "modulate:a", 1.0, 0.35)

func _draw_bar() -> void:
	var outer := Rect2(Vector2.ZERO, _bar.size)
	_bar.draw_rect(outer, KwentaStyle.INK)
	var inner := outer.grow(-3.0)
	_bar.draw_rect(inner, TRACK)

	var seg_w := (inner.size.x - SEG_GAP * float(SEGMENTS + 1)) / float(SEGMENTS)
	var seg_h := inner.size.y - SEG_GAP * 2.0
	var fill_color := _color_for(_display)
	for i in SEGMENTS:
		var x := inner.position.x + SEG_GAP + float(i) * (seg_w + SEG_GAP)
		var y := inner.position.y + SEG_GAP
		_bar.draw_rect(Rect2(x, y, seg_w, seg_h), SEG_EMPTY)
		var fraction := clampf(_display / 10.0 - float(i), 0.0, 1.0)
		if fraction > 0.0:
			_bar.draw_rect(Rect2(x, y, seg_w * fraction, seg_h), fill_color)
			# light strip on top so the chunk looks like a pixel-art block
			_bar.draw_rect(Rect2(x, y, seg_w * fraction, 3.0), fill_color.lightened(0.35))

func _draw() -> void:
	if not _hanging:
		return
	var cx := size.x * 0.5
	draw_line(Vector2(cx, 0.0), Vector2(cx, STRING_LEN + 14.0), STRING_COLOR, 3.0)

func _draw_hole(canvas: Control) -> void:
	var center := Vector2(size.x * 0.5, STRING_LEN + 14.0)
	canvas.draw_circle(center, 9.0, KwentaStyle.PAPER_DARK)
	canvas.draw_arc(center, 9.0, 0.0, TAU, 24, KwentaStyle.INK, 3.0)
	canvas.draw_circle(center, 4.0, Color("#3a2a1d"))
