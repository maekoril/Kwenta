extends Control
## Launch-only opening, drawn over the real menu so the final fade is seamless.

const END_TIME := 5.5
const TEAM_LOGO: Texture2D = preload("res://assets/branding/team_uri_logo.png")
const LIGHT := Color("fffaeb")
var elapsed := 0.0
var _skip_started := -1.0

func _ready() -> void:
	name = "OpeningSplash"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 4096
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	queue_redraw()

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= END_TIME or (_skip_started >= 0.0 and elapsed - _skip_started >= 0.25):
		queue_free()
	queue_redraw()

func _input(event: InputEvent) -> void:
	# Consume the entire gesture, including release, before revealing menu input.
	if event is InputEventMouse or event is InputEventScreenTouch or event is InputEventScreenDrag or event is InputEventKey or event is InputEventJoypadButton:
		get_viewport().set_input_as_handled()
		if elapsed > 0.6 and event.is_pressed() and _skip_started < 0.0:
			_skip_started = elapsed

func _ease(value: float) -> float:
	var t := clampf(value, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)

func _text_center(text: String, at: Vector2, font_size: int, color: Color) -> void:
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(font, at - Vector2(width * 0.5, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _draw() -> void:
	modulate.a = 1.0 if _skip_started < 0.0 else 1.0 - _ease((elapsed - _skip_started) / 0.25)
	var fit := size.y / 450.0
	if fit <= 0.0:
		return
	var width := size.x / fit
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE * fit)
	var screen := Rect2(0, 0, width, 450)
	if elapsed < 1.5:
		draw_rect(screen, Color.BLACK)
		var alpha := _ease(elapsed / 0.35) * (1.0 - _ease((elapsed - 1.05) / 0.4))
		draw_texture_rect(TEAM_LOGO, Rect2(width * 0.5 - 140, 65, 280, 280), false, Color(1, 1, 1, alpha))
		_text_center("P R E S E N T S", Vector2(width * 0.5, 367), 15, Color(0.96, 0.93, 0.86, alpha))
		return
	var t := elapsed - 1.5
	if t >= 3.15:
		draw_rect(screen, Color(LIGHT, 1.0 - _ease((t - 3.25) / 0.75)))
		return
	draw_rect(screen, LIGHT)
	var opening := _ease((t - 0.4) / 2.05)
	var offset := -450.0 * opening
	# Rolling metal slats move upward together, exposing daylight below.
	for slat in range(15):
		var y := slat * 30.0 + offset
		var top := maxf(0.0, y)
		var bottom := minf(450.0, y + 30.0)
		if bottom <= top:
			continue
		draw_rect(Rect2(0, top, width, bottom - top), Color("292a2a"))
		for stripe in range(1, 15):
			var sy := y + stripe * 2.0
			if sy >= 0.0 and sy < 450.0:
				var brightness := 0.13 + 0.025 * sin(stripe / 15.0 * PI)
				draw_line(Vector2(0, sy), Vector2(width, sy), Color(brightness, brightness, brightness), 2.0)
		if y >= 0.0:
			draw_line(Vector2(0, y), Vector2(width, y), Color("101112"), 3.0)
		if y + 3.0 >= 0.0 and y + 3.0 < 450.0:
			draw_line(Vector2(0, y + 3.0), Vector2(width, y + 3.0), Color("3d3c38"), 1.0)
	var edge := 450.0 + offset
	if edge > 0.0:
		draw_rect(Rect2(0, maxf(0.0, edge - 13.0), width, minf(edge, 13.0)), Color("161718"))
		if edge > 61.0:
			draw_rect(Rect2(width * 0.5 - 42, edge - 61, 84, 24), Color("111213"))
			draw_line(Vector2(width * 0.5 - 30, edge - 52), Vector2(width * 0.5 + 30, edge - 52), Color("5f5e56"), 3.0)
	if opening > 0.0:
		for layer in range(20, 0, -1):
			draw_line(Vector2(0, edge), Vector2(width, edge), Color(1.0, 0.95, 0.8, 0.012 * opening), layer * 3.0)
	draw_rect(screen, Color(LIGHT, _ease((opening - 0.65) / 0.35) * 0.5))
	draw_rect(screen, Color(0, 0, 0, 1.0 - _ease(t / 0.3)))
