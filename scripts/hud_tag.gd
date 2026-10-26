class_name HudTag
extends Control

# A paper price tag hanging from a string, swaying gently. The HUD is four of these
# (day, clock, cash, story) hanging from the roof edge, like the price tags in a sari-sari store.
# It holds a Label that the game already updates, so no other code has to change.

const STRING_LEN := 16.0
const BODY_H := 72.0
const STRING_COLOR := Color("#6b4a2a")

var _sway_degrees: float = 0.0
var _sway_seconds: float = 3.0
var _sway: Tween

func setup(content: Label, width: float, fill: Color, sway_degrees: float, sway_seconds: float) -> HudTag:
	size = Vector2(width, STRING_LEN + BODY_H)
	custom_minimum_size = size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	pivot_offset = Vector2(width * 0.5, 0.0)    # swings from the top of the string
	_sway_degrees = sway_degrees
	_sway_seconds = sway_seconds

	var body := PanelContainer.new()
	body.position = Vector2(0.0, STRING_LEN)
	body.size = Vector2(width, BODY_H)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_theme_stylebox_override("panel", KwentaStyle.box(fill, KwentaStyle.INK, 18.0, 8.0, 10, 4, 6))
	add_child(body)

	content.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	KwentaStyle.apply_font(content)
	body.add_child(content)

	# Punched hole with a reinforcement ring, drawn over the tag body.
	var hole := Control.new()
	hole.size = size
	hole.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hole.draw.connect(_draw_hole.bind(hole))
	add_child(hole)
	queue_redraw()
	return self

func _ready() -> void:
	if _sway_degrees <= 0.0:
		return
	rotation_degrees = randf_range(-_sway_degrees, _sway_degrees)
	_sway = create_tween().set_loops()
	_sway.tween_property(self, "rotation_degrees", _sway_degrees, _sway_seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_sway.tween_property(self, "rotation_degrees", -_sway_degrees, _sway_seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _draw() -> void:
	# The string, from the top edge down to the hole.
	var cx := size.x * 0.5
	draw_line(Vector2(cx, 0.0), Vector2(cx, STRING_LEN + 14.0), STRING_COLOR, 3.0)

func _draw_hole(canvas: Control) -> void:
	var center := Vector2(size.x * 0.5, STRING_LEN + 14.0)
	canvas.draw_circle(center, 9.0, KwentaStyle.PAPER_DARK)
	canvas.draw_arc(center, 9.0, 0.0, TAU, 24, KwentaStyle.INK, 3.0)
	canvas.draw_circle(center, 4.0, Color("#3a2a1d"))
