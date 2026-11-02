extends VBoxContainer

func _draw() -> void:
	var width := size.x + 38.0
	var y := 66.0
	while y < size.y:
		draw_line(Vector2(-15, y), Vector2(width, y), Color(0.43, 0.60, 0.67, 0.35), 1.5)
		y += 48.0
	draw_line(Vector2(1, -17), Vector2(1, size.y + 18), Color(0.75, 0.34, 0.30, 0.42), 2.0)
