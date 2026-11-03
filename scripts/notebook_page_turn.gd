extends Control

var progress := 0.0:
	set(value):
		progress = value
		queue_redraw()
var direction := 1
var spread: Texture2D

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(1400, 850)
	visible = false

func capture(book: Control) -> void:
	spread = null
	if DisplayServer.get_name() == "headless": return
	# Copy the rendered spread so ink and photographs bend with the paper.
	var frame := book.get_viewport().get_texture().get_image()
	if frame == null or frame.is_empty(): return
	var bounds := book.get_global_transform_with_canvas() * Rect2(65, 145, 1261, 595)
	var crop := Rect2i(bounds).intersection(Rect2i(Vector2i.ZERO, frame.get_size()))
	if not crop.has_area(): return
	spread = ImageTexture.create_from_image(frame.get_region(crop))

func _draw() -> void:
	var t := clampf(progress, 0.0, 1.0)
	var angle := PI * t
	var side := 1.0 if direction > 0 else -1.0
	var hinge := 695.5
	var width := 630.5
	var bend := sin(angle)
	# The stationary old leaf remains until the turning sheet crosses the spine.
	if spread != null and t < 0.5:
		var left := 65.0 if direction > 0 else hinge
		var source_x := 0.0 if direction > 0 else 0.5
		draw_texture_rect_region(spread, Rect2(left, 145, width, 595), Rect2(source_x * spread.get_width(), 0, spread.get_width() * 0.5, spread.get_height()))
	var tip := hinge + side * width * cos(angle)
	var shadow_left := minf(hinge, tip)
	for layer in range(10, 0, -1):
		draw_rect(Rect2(shadow_left - layer * 2, 148 + layer, absf(tip - hinge) + layer * 4, 589), Color(0.19, 0.11, 0.04, bend * 0.018))
	# Narrow textured strips form a curved sheet, lifted at its outer corners.
	for strip in range(48):
		var u0 := float(strip) / 48.0
		var u1 := float(strip + 1) / 48.0
		var x0 := hinge + side * (width * u0 * cos(angle) + sin(u0 * PI) * bend * 32.0)
		var x1 := hinge + side * (width * u1 * cos(angle) + sin(u1 * PI) * bend * 32.0)
		var lift0 := sin(u0 * PI * 0.5) * bend * 32.0
		var lift1 := sin(u1 * PI * 0.5) * bend * 32.0
		var points := PackedVector2Array([Vector2(x0, 145 - lift0), Vector2(x1, 145 - lift1), Vector2(x1, 740 + lift1 * 0.4), Vector2(x0, 740 + lift0 * 0.4)])
		var shade := 1.0 - bend * (0.12 + 0.22 * sin(u0 * PI))
		if t < 0.5 and spread != null:
			var uv0 := 0.5 + side * u0 * 0.5
			var uv1 := 0.5 + side * u1 * 0.5
			draw_polygon(points, PackedColorArray([Color(shade, shade, shade)]), PackedVector2Array([Vector2(uv0, 0), Vector2(uv1, 0), Vector2(uv1, 1), Vector2(uv0, 1)]), spread)
		else:
			var opacity := 1.0 - smoothstep(0.78, 1.0, t)
			draw_polygon(points, PackedColorArray([Color(1.0 * shade, 0.945 * shade, 0.827 * shade, opacity)]))
			for line in range(218, 727, 46):
				var fraction := float(line - 145) / 595.0
				draw_line(Vector2(x0, lerpf(145 - lift0, 740 + lift0 * 0.4, fraction)), Vector2(x1, lerpf(145 - lift1, 740 + lift1 * 0.4, fraction)), Color(0.55, 0.66, 0.65, opacity * 0.3), 1.0, true)
