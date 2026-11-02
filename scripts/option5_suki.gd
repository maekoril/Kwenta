extends "res://scripts/trust_tag.gd"

# Compact, textured variant of the existing Suki Meter.
# The base TrustTag still supplies set_trust(), tweens, pulsing, and warning states.

func setup(initial_value: float, width: float, sway_degrees: float, sway_seconds: float, hanging: bool = true) -> TrustTag:
	_hanging = false
	_sway_degrees = 0.0
	_sway_seconds = sway_seconds
	_target = clampf(initial_value, 0.0, 100.0)
	_display = _target
	size = Vector2(width, 74.0)
	custom_minimum_size = size
	pivot_offset = size * 0.5
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var frame := StyleBoxTexture.new()
	frame.texture = load("res://assets/sprites/ui/hud_v5/dark_capsule.png") as Texture2D
	frame.texture_margin_left = 30.0
	frame.texture_margin_right = 30.0
	frame.texture_margin_top = 22.0
	frame.texture_margin_bottom = 22.0
	frame.content_margin_left = 20.0
	frame.content_margin_right = 20.0
	frame.content_margin_top = 12.0
	frame.content_margin_bottom = 12.0

	var panel := PanelContainer.new()
	panel.name = "SukiMeterFrame"
	panel.size = size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", frame)
	add_child(panel)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 7)
	panel.add_child(row)
	var heart := TextureRect.new()
	heart.name = "Heart"
	heart.texture = load("res://assets/sprites/ui/hud_v5/heart.png") as Texture2D
	heart.custom_minimum_size = Vector2(40.0, 40.0)
	heart.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	heart.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(heart)

	# Option 5 is a single unobstructed row: heart | green bar | 100.
	_bar = Control.new()
	_bar.name = "SukiSegments"
	_bar.custom_minimum_size = Vector2(0.0, 24.0)
	_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar.draw.connect(_draw_bar)
	row.add_child(_bar)
	_value_label = KwentaStyle.make_label(str(roundi(_display)), 24, Color("fff0d3"))
	_value_label.name = "SukiValue"
	_value_label.custom_minimum_size = Vector2(46.0, 0.0)
	_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(_value_label)
	_refresh_warning()
	return self

func _draw_bar() -> void:
	var area := Rect2(Vector2.ZERO, _bar.size)
	var track := StyleBoxFlat.new()
	track.bg_color = Color("170c08")
	track.border_color = Color("a7733c")
	track.set_border_width_all(2)
	track.set_corner_radius_all(8)
	_bar.draw_style_box(track, area)
	var inner := area.grow(-4.0)
	var gap := 2.2
	var bar_width := (inner.size.x - gap * 11.0) / 10.0
	var color := _color_for(_display)
	for i in 10:
		var x := inner.position.x + gap + float(i) * (bar_width + gap)
		var y := inner.position.y + 1.0
		var height := maxf(1.0, inner.size.y - 2.0)
		_bar.draw_rect(Rect2(x, y, bar_width, height), Color("493320"))
		var filled := clampf(_display / 10.0 - float(i), 0.0, 1.0)
		if filled > 0.0:
			_bar.draw_rect(Rect2(x, y, bar_width * filled, height), color)
			_bar.draw_rect(Rect2(x, y, bar_width * filled, 2.0), color.lightened(0.4))
