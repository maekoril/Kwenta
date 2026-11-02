extends Control

var progress := 0.0:
	set(value):
		progress = value
		queue_redraw()
var direction := 1

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(1400, 850)
	visible = false

func _draw() -> void:
	var t := clampf(progress, 0.0, 1.0)
	var fold_x := lerpf(1326.0, 74.0, t) if direction > 0 else lerpf(74.0, 1326.0, t)
	var width := 185.0 * sin(PI * t)
	if width < 1.0: return
	var side := -1.0 if direction > 0 else 1.0
	var y_top := 151.0
	var y_bottom := 734.0
	var outer_x := fold_x - side * width
	draw_polygon(PackedVector2Array([Vector2(fold_x, y_top), Vector2(outer_x, y_top + 17), Vector2(outer_x, y_bottom - 17), Vector2(fold_x, y_bottom)]), PackedColorArray([Color("e5d2aa"), Color("fff4d9"), Color("f9e9c5"), Color("dcc39a")]))
	draw_line(Vector2(fold_x, y_top), Vector2(fold_x, y_bottom), Color("8c6e50", 0.55), 3.0, true)
	for y in range(218, 700, 46):
		draw_line(Vector2(fold_x - side * 8, y), Vector2(outer_x + side * 12, y), Color("a3b8b4", 0.25), 1.0, true)
