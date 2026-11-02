extends Control

func _ready() -> void:
	size = Vector2(64, 72)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	# A coin being received by an open hand, on a green badge.
	draw_circle(Vector2(32, 34), 30, Color("352615"))
	draw_circle(Vector2(32, 34), 27, Color("4c8c58"))
	draw_arc(Vector2(32, 34), 24, 0, TAU, 32, Color("b7d99a"), 2, true)
	draw_circle(Vector2(33, 21), 11, Color("523619"))
	draw_circle(Vector2(33, 21), 8, Color("f0bd50"))
	draw_arc(Vector2(33, 21), 5, 0, TAU, 24, Color("fff0ba"), 1.5, true)
	var hand := PackedVector2Array([Vector2(10, 42), Vector2(19, 38), Vector2(27, 40), Vector2(39, 39), Vector2(45, 35), Vector2(50, 36), Vector2(47, 43), Vector2(37, 49), Vector2(23, 50), Vector2(16, 47), Vector2(10, 49)])
	draw_colored_polygon(hand, Color("3c291b"))
	var palm := PackedVector2Array([Vector2(13, 43), Vector2(19, 41), Vector2(26, 43), Vector2(39, 42), Vector2(46, 38), Vector2(47, 39), Vector2(44, 42), Vector2(36, 46), Vector2(24, 47), Vector2(17, 44), Vector2(13, 46)])
	draw_colored_polygon(palm, Color("ffe2a8"))
