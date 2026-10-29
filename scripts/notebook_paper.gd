class_name NotebookPaper
extends Control

# Decoration for the earnings page: ruled lines, a red margin line and punched holes,
# like the old kuwaderno. Add it as the FIRST child of a PanelContainer so it sits behind
# the content. It draws outside its own rect, across the whole page including the margins,
# so the pad_* values should match the panel's content margins.

var pad_left: float = 100.0
var pad_right: float = 56.0
var pad_top: float = 36.0
var pad_bottom: float = 36.0
var line_gap: float = 52.0

func _draw() -> void:
	var left := -pad_left + 14.0
	var right := size.x + pad_right - 14.0
	var top := -pad_top + 120.0
	var bottom := size.y + pad_bottom - 28.0
	var y := top
	while y < bottom:
		draw_line(Vector2(left, y), Vector2(right, y), Color("#9fb4c8", 0.45), 2.0)
		y += line_gap
	# Red margin line.
	var margin_x := -pad_left * 0.28
	draw_line(Vector2(margin_x, -pad_top + 16.0), Vector2(margin_x, size.y + pad_bottom - 16.0), Color("#d9857a", 0.75), 3.0)
	# Punched holes down the left edge.
	var hole_x := -pad_left + 34.0
	var page_height := size.y + pad_top + pad_bottom
	for fraction in [0.16, 0.5, 0.84]:
		var center := Vector2(hole_x, -pad_top + page_height * fraction)
		draw_circle(center, 14.0, Color("#3a2a1d"))
		draw_arc(center, 14.0, 0.0, TAU, 24, Color("#2b1a10"), 3.0)
