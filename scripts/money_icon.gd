class_name MoneyIcon
extends Control

# A coin or bill drawn in code, so there are no art assets to wait for.
# Bill colors follow the Philippine notes: 20 orange, 50 red, 100 violet, 200 green.
# Replace _draw() with a TextureRect when you have real sprites.

signal tapped

var value: int = 1
var pressable: bool = false

static func is_bill(amount: int) -> bool:
	return amount >= 20

static func size_for(amount: int, height: float) -> Vector2:
	if is_bill(amount):
		return Vector2(height * 1.75, height)
	return Vector2(height, height)

# [fill, edge, text]
static func colors_for(amount: int) -> Array[Color]:
	match amount:
		1:
			return [Color("#dfe3e6"), Color("#7d858c"), Color("#2b1a10")]
		5:
			return [Color("#c9ced2"), Color("#6a727a"), Color("#2b1a10")]
		10:
			return [Color("#e8c25a"), Color("#a67c1a"), Color("#2b1a10")]
		20:
			return [Color("#f1a24a"), Color("#a85d12"), Color("#2b1a10")]
		50:
			return [Color("#d9534f"), Color("#7e1f1c"), Color("#fff0cf")]
		100:
			return [Color("#8e6bbf"), Color("#4b2f7a"), Color("#fff0cf")]
	return [Color("#58a65c"), Color("#2a6a2e"), Color("#fff0cf")]

func setup(amount: int, height: float, can_press: bool) -> MoneyIcon:
	value = amount
	pressable = can_press
	custom_minimum_size = size_for(amount, height)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_STOP if can_press else Control.MOUSE_FILTER_IGNORE
	queue_redraw()
	return self

func pop() -> void:
	pivot_offset = size * 0.5
	scale = Vector2(0.86, 0.86)
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _gui_input(event: InputEvent) -> void:
	if pressable and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		tapped.emit()

func _draw() -> void:
	var colors := colors_for(value)
	var font := ThemeDB.fallback_font
	var label := "₱%d" % value
	if is_bill(value):
		var box := StyleBoxFlat.new()
		box.bg_color = colors[0]
		box.border_color = colors[1]
		box.set_border_width_all(4)
		box.set_corner_radius_all(8)
		draw_style_box(box, Rect2(Vector2.ZERO, size))
		draw_rect(Rect2(size.x * 0.07, size.y * 0.15, size.x * 0.86, size.y * 0.70), colors[1], false, 2.0)
		var font_size := int(size.y * 0.46)
		draw_string(font, Vector2(0.0, size.y * 0.5 + font_size * 0.35), label, HORIZONTAL_ALIGNMENT_CENTER, size.x, font_size, colors[2])
	else:
		var center := size * 0.5
		var radius := minf(size.x, size.y) * 0.5 - 2.0
		draw_circle(center, radius, colors[0])
		draw_arc(center, radius - 2.0, 0.0, TAU, 48, colors[1], 5.0)
		draw_arc(center, radius * 0.68, 0.0, TAU, 40, colors[1], 2.0)
		var font_size := int(size.y * 0.40)
		draw_string(font, Vector2(0.0, size.y * 0.5 + font_size * 0.35), label, HORIZONTAL_ALIGNMENT_CENTER, size.x, font_size, colors[2])
