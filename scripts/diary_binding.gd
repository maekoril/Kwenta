extends Control

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("b58a58"))
	draw_rect(Rect2(4, 0, size.x - 8, size.y), Color("e0c39a"))
	var y := 38.0
	while y < size.y - 15:
		draw_circle(Vector2(8, y), 7, Color("513722"))
		draw_circle(Vector2(size.x - 8, y), 7, Color("513722"))
		draw_arc(Vector2(size.x * 0.5, y - 2), size.x * 0.4, PI, TAU, 24, Color("523a2b"), 5.0, true)
		draw_line(Vector2(size.x * 0.1, y - 2), Vector2(size.x * 0.9, y - 2), Color("715241"), 4.0, true)
		y += 76.0
