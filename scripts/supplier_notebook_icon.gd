extends Control

# A small notebook drawn in the same ink and paper colors as the HUD.
func _draw() -> void:
	var ink := Color("342019")
	var cover := Color("a85d2d")
	var paper := Color("f6e7c8")
	draw_rect(Rect2(6, 4, 31, 42), ink)
	draw_rect(Rect2(9, 7, 25, 36), cover)
	draw_rect(Rect2(14, 11, 17, 27), paper)
	for y in [17.0, 23.0, 29.0, 35.0]:
		draw_line(Vector2(17, y), Vector2(28, y), Color("a7734e"), 1.5)
	for y in [12.0, 21.0, 30.0, 39.0]:
		draw_line(Vector2(3, y), Vector2(12, y), ink, 3.0)
