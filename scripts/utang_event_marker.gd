extends Control

func _ready() -> void:
	size = Vector2(64, 72)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	# A ledger and coin: no letters or font-dependent currency glyphs.
	draw_style_box(KwentaStyle.box(Color("704321"), Color("e7b867"), 0, 0, 7, 3, 3), Rect2(3, 2, 44, 58))
	draw_style_box(KwentaStyle.box(Color("fff1ce"), Color("46230e"), 0, 0, 3, 2, 0), Rect2(11, 7, 30, 46))
	for y in [18, 28, 38]:
		draw_line(Vector2(17, y), Vector2(34, y), Color("92673f"), 3)
	for y in [14, 30, 46]:
		draw_line(Vector2(0, y), Vector2(10, y), Color("e7b867"), 4)
	draw_circle(Vector2(45, 53), 17, Color("46230e"))
	draw_circle(Vector2(45, 53), 14, Color("edb342"))
	draw_arc(Vector2(45, 53), 10, 0, TAU, 32, Color("fff1ce"), 2, true)
