extends Control

var progress := 0.0:
	set(value):
		progress = clampf(value, 0.0, 1.0)
		queue_redraw()

func _draw() -> void:
	if progress <= 0.0:
		return
	# Each bristle deposits paint along a fixed path. Already painted marks stay
	# in place instead of stretching as the leading edge moves across the text.
	var width := maxf(0.0, size.x - 18.0)
	for bristle in range(26):
		var across := (float(bristle) + 0.5) / 26.0
		var edge := absf(across * 2.0 - 1.0)
		var seed_phase := float(bristle) * 2.399
		var start := 0.012 + edge * 0.023 + (sin(seed_phase) + 1.0) * 0.009
		var finish := 0.98 - edge * 0.038 + sin(seed_phase * 1.7) * 0.018
		var tip := minf(finish, progress * 1.09 - edge * 0.035 + sin(seed_phase) * 0.012)
		if tip <= start:
			continue
		var upper := PackedVector2Array()
		var lower := PackedVector2Array()
		var steps := maxi(2, ceili((tip - start) * 70.0))
		for step in range(steps + 1):
			var u := lerpf(start, tip, float(step) / steps)
			# Pressure builds at contact, then lifts toward the end of the stroke.
			var pressure := (0.78 + 0.22 * sin(PI * u)) * (1.0 - 0.20 * smoothstep(0.80, 1.0, u))
			var center := size.y * (0.53 - 0.045 * sin(u * PI) + 0.018 * sin(u * TAU))
			var grain := sin(u * 43.0 + seed_phase) * 0.45 + sin(u * 91.0 + seed_phase) * 0.22
			var y := center + (across - 0.5) * size.y * 0.66 * pressure + grain
			var thickness := size.y * 0.66 / 26.0 * pressure
			# Fine gaps between occasional bristles expose the notebook underneath.
			var coverage := 0.69 if bristle % 7 == 0 else 1.08
			upper.append(Vector2(9.0 + width * u, y - thickness * coverage * 0.5))
			lower.append(Vector2(9.0 + width * u, y + thickness * coverage * 0.5))
		lower.reverse()
		upper.append_array(lower)
		var pigment := 0.60 + 0.13 * (sin(seed_phase) * 0.5 + 0.5)
		draw_colored_polygon(upper, Color(1.0, 0.73 + 0.035 * sin(seed_phase), 0.20, pigment))
