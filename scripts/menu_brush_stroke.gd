extends Control

var progress := 0.0:
	set(value):
		progress = clampf(value, 0.0, 1.0)
		queue_redraw()

func _draw() -> void:
	if progress <= 0.0:
		return
	var left := 5.0
	var width := maxf(0.0, size.x - 10.0) * progress
	var top := size.y * 0.14
	var height := size.y * 0.72
	var points := PackedVector2Array([
		Vector2(left, top + height * 0.17),
		Vector2(left + width * 0.18, top + height * 0.05),
		Vector2(left + width * 0.44, top + height * 0.09),
		Vector2(left + width * 0.74, top),
		Vector2(left + width * 0.97, top + height * 0.10),
		Vector2(left + width * 0.93, top + height * 0.26),
		Vector2(left + width, top + height * 0.35),
		Vector2(left + width * 0.96, top + height * 0.52),
		Vector2(left + width, top + height * 0.68),
		Vector2(left + width * 0.93, top + height * 0.79),
		Vector2(left + width * 0.98, top + height * 0.91),
		Vector2(left + width * 0.63, top + height * 0.95),
		Vector2(left + width * 0.36, top + height * 0.91),
		Vector2(left + width * 0.10, top + height),
		Vector2(left, top + height * 0.87),
		Vector2(left + width * 0.04, top + height * 0.70),
		Vector2(left, top + height * 0.50),
	])
	draw_colored_polygon(points, Color(1.0, 0.71, 0.19, 0.76))
