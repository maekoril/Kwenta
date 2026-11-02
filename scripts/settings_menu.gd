extends CanvasLayer

const AUDIO_SETTINGS = preload("res://scripts/audio_settings.gd")
const HANDWRITING: Font = preload("res://assets/fonts/Caveat.ttf")
var overlay: Control
var music_slider: HSlider
var sfx_slider: HSlider
var settings_panel: PanelContainer

func _ready() -> void:
	layer = 110
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	get_viewport().size_changed.connect(_fit_panel)

func _build() -> void:
	overlay = Control.new()
	overlay.name = "SettingsOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.visible = false
	add_child(overlay)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.08, 0.04, 0.02, 0.75)
	overlay.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel := PanelContainer.new()
	settings_panel = panel
	panel.custom_minimum_size = Vector2(800, 0)
	panel.add_theme_stylebox_override("panel", KwentaStyle.box(Color("f5e5c6"), Color("704225"), 66, 42, 18, 7, 9))
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	panel.add_child(column)
	var eyebrow := KwentaStyle.make_label("KWENTA  /  SETTINGS", 20, Color("936a43"))
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(eyebrow)
	var heading := KwentaStyle.make_label("Sound Settings", 64, KwentaStyle.INK)
	heading.add_theme_font_override("font", HANDWRITING)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(heading)
	var separator := ColorRect.new()
	separator.color = Color("c7a77d")
	separator.custom_minimum_size.y = 2
	separator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(separator)
	music_slider = _add_slider(column, "MUSIC", AUDIO_SETTINGS.MUSIC_BUS)
	sfx_slider = _add_slider(column, "SOUND EFFECTS", AUDIO_SETTINGS.SFX_BUS)
	var close_button := Button.new()
	close_button.name = "CloseSettingsButton"
	close_button.text = "BACK"
	close_button.custom_minimum_size.y = 68
	KwentaStyle.style_button(close_button, Color("dca343"), 28)
	close_button.pressed.connect(close)
	column.add_child(close_button)

func _add_slider(column: VBoxContainer, label_text: String, bus: String) -> HSlider:
	var group := VBoxContainer.new()
	group.add_theme_constant_override("separation", 2)
	column.add_child(group)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	group.add_child(row)
	var label := KwentaStyle.make_label(label_text, 27, KwentaStyle.INK)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var percent := KwentaStyle.make_label("100%", 25, Color("8c5528"))
	percent.custom_minimum_size.x = 72
	percent.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(percent)
	var slider := HSlider.new()
	slider.name = "%sSlider" % bus
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	slider.value = 100
	slider.custom_minimum_size = Vector2(250, 56)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_slider(slider)
	group.add_child(slider)
	slider.value_changed.connect(func(value: float):
		percent.text = "%d%%" % roundi(value)
		AUDIO_SETTINGS.set_volume(bus, value / 100.0)
		AUDIO_SETTINGS.save()
	)
	return slider

func _style_slider(slider: HSlider) -> void:
	var track := StyleBoxFlat.new()
	track.bg_color = Color("d5bd96")
	track.set_corner_radius_all(8)
	track.content_margin_top = 7
	track.content_margin_bottom = 7
	var fill := track.duplicate() as StyleBoxFlat
	fill.bg_color = Color("bb762c")
	slider.add_theme_stylebox_override("slider", track)
	slider.add_theme_stylebox_override("grabber_area", fill)
	slider.add_theme_stylebox_override("grabber_area_highlight", fill)
	var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="34" height="34"><circle cx="17" cy="17" r="15" fill="#694126"/><circle cx="17" cy="17" r="11" fill="#f4d58e"/><circle cx="17" cy="17" r="5" fill="#d99b42"/></svg>'
	var image := Image.new()
	if image.load_svg_from_buffer(svg.to_utf8_buffer(), 1.0) == OK:
		var knob := ImageTexture.create_from_image(image)
		slider.add_theme_icon_override("grabber", knob)
		slider.add_theme_icon_override("grabber_highlight", knob)

func open() -> void:
	music_slider.value = roundi(AUDIO_SETTINGS.get_volume(AUDIO_SETTINGS.MUSIC_BUS) * 100)
	sfx_slider.value = roundi(AUDIO_SETTINGS.get_volume(AUDIO_SETTINGS.SFX_BUS) * 100)
	overlay.visible = true
	_fit_panel.call_deferred()

func _fit_panel() -> void:
	if not is_instance_valid(settings_panel):
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var panel_size := settings_panel.size
	if panel_size.x <= 0.0 or panel_size.y <= 0.0:
		return
	settings_panel.pivot_offset = panel_size * 0.5
	var fit := minf(1.0, minf(maxf(1.0, viewport_size.x - 80.0) / panel_size.x, maxf(1.0, viewport_size.y - 80.0) / panel_size.y))
	settings_panel.scale = Vector2.ONE * fit

func close() -> void:
	overlay.visible = false

func _input(event: InputEvent) -> void:
	if overlay != null and overlay.visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
