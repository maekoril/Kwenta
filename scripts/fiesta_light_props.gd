extends Control

const LIGHT_PROPS = preload("res://assets/store/fiesta_light_props.png")

func _draw() -> void:
	# The two painted props share a transparent sprite sheet. Their bases sit on
	# the side counters; the illumination itself is handled by the shade shader.
	draw_texture_rect_region(LIGHT_PROPS, Rect2(128, 410, 148, 56), Rect2(150, 270, 960, 370))
	draw_texture_rect_region(LIGHT_PROPS, Rect2(1680, 383, 62, 70), Rect2(1435, 125, 460, 525))
