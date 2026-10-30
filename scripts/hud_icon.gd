class_name HudIcon
extends Control

# Tiny HUD icons drawn in code (no image files needed). Designed on a 40x40 grid and
# scaled to whatever size you ask for, in the same ink-outline look as the paper tags.

enum Kind { CALENDAR, CLOCK, COIN, CLIPBOARD, PESO, HEART }

var kind: int = Kind.CALENDAR
var ink: Color = KwentaStyle.INK
var fill: Color = KwentaStyle.PAPER

func setup(icon_kind: int, size_px: float, ink_color: Color, fill_color: Color) -> HudIcon:
	kind = icon_kind
	ink = ink_color
	fill = fill_color
	custom_minimum_size = Vector2(size_px, size_px)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return self

func _draw() -> void:
	var s := size.x / 40.0
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(s, s))
	match kind:
		Kind.CALENDAR:
			# Cream calendar page, red header (fill), ink outline.
			draw_rect(Rect2(5, 8, 30, 28), KwentaStyle.PAPER)
			draw_rect(Rect2(5, 8, 30, 28), ink, false, 3.0)
			draw_rect(Rect2(7, 10, 26, 9), fill)
			draw_rect(Rect2(11, 3, 4, 9), ink)
			draw_rect(Rect2(25, 3, 4, 9), ink)
			for row in 2:
				for col in 3:
					draw_rect(Rect2(10 + col * 8, 22 + row * 7, 5, 4), ink)
		Kind.CLOCK:
			draw_circle(Vector2(20, 20), 16.0, fill)
			draw_arc(Vector2(20, 20), 16.0, 0.0, TAU, 32, ink, 3.0)
			draw_line(Vector2(20, 20), Vector2(20, 9), ink, 3.0)
			draw_line(Vector2(20, 20), Vector2(28, 24), ink, 3.0)
			draw_circle(Vector2(20, 20), 2.5, ink)
		Kind.COIN:
			draw_circle(Vector2(20, 20), 16.0, KwentaStyle.GOLD)
			draw_arc(Vector2(20, 20), 16.0, 0.0, TAU, 32, ink, 3.0)
			draw_arc(Vector2(20, 20), 9.0, 0.0, TAU, 24, ink, 2.0)
			draw_line(Vector2(20, 14), Vector2(20, 26), ink, 3.0)
		Kind.CLIPBOARD:
			draw_rect(Rect2(7, 6, 26, 31), fill)
			draw_rect(Rect2(7, 6, 26, 31), ink, false, 3.0)
			draw_rect(Rect2(14, 2, 12, 8), KwentaStyle.GOLD)
			draw_rect(Rect2(14, 2, 12, 8), ink, false, 2.0)
			for i in 3:
				draw_line(Vector2(13, 18 + i * 7), Vector2(27, 18 + i * 7), ink, 2.5)
		Kind.PESO:
			# Peso sign drawn in `ink` (pass the money green).
			draw_line(Vector2(13, 5), Vector2(13, 35), ink, 4.0)
			draw_line(Vector2(13, 6), Vector2(22, 6), ink, 4.0)
			draw_arc(Vector2(22, 14), 8.0, -PI / 2.0, PI / 2.0, 16, ink, 4.0)
			draw_line(Vector2(22, 22), Vector2(13, 22), ink, 4.0)
			draw_line(Vector2(6, 13), Vector2(32, 13), ink, 3.0)
			draw_line(Vector2(6, 19), Vector2(32, 19), ink, 3.0)
		Kind.HEART:
			# Heart drawn in `fill` with a dark outline.
			var outline := Color("#2b1a10")
			draw_circle(Vector2(13, 15), 10.5, outline)
			draw_circle(Vector2(27, 15), 10.5, outline)
			draw_colored_polygon(PackedVector2Array([Vector2(3.2, 19.0), Vector2(36.8, 19.0), Vector2(20, 37.5)]), outline)
			draw_circle(Vector2(13, 15), 8.0, fill)
			draw_circle(Vector2(27, 15), 8.0, fill)
			draw_colored_polygon(PackedVector2Array([Vector2(5.0, 18.0), Vector2(35.0, 18.0), Vector2(20, 34.0)]), fill)
			draw_circle(Vector2(10, 12), 2.5, fill.lightened(0.45))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
