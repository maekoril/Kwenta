class_name FiestaHelperIcon
extends Button

var portrait: TextureRect
var countdown: Label
var selected_marker: Label
var role_label: Label
var _selected := false
var _selection_tween: Tween

func _init() -> void:
	custom_minimum_size = Vector2(210, 155)
	flat = true
	focus_mode = Control.FOCUS_ALL
	for style in ["normal", "hover", "pressed", "disabled", "focus"]:
		add_theme_stylebox_override(style, StyleBoxEmpty.new())
	portrait = TextureRect.new()
	portrait.position = Vector2(112, 0)
	portrait.size = Vector2(110, 155)
	portrait.pivot_offset = Vector2(110, 78)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gray_shader := Shader.new()
	gray_shader.code = "shader_type canvas_item; uniform bool grayscale = false; void fragment() { if (grayscale) { float g = dot(COLOR.rgb, vec3(0.299, 0.587, 0.114)); COLOR.rgb = vec3(g * 0.65); } }"
	var material := ShaderMaterial.new()
	material.shader = gray_shader
	portrait.material = material
	add_child(portrait)
	countdown = Label.new()
	countdown.position = Vector2(115, 38)
	countdown.size = Vector2(85, 65)
	countdown.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	countdown.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	countdown.add_theme_font_size_override("font_size", 38)
	countdown.add_theme_color_override("font_color", Color.WHITE)
	countdown.add_theme_color_override("font_outline_color", Color("2b1a10"))
	countdown.add_theme_constant_override("outline_size", 7)
	countdown.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(countdown)
	selected_marker = Label.new()
	selected_marker.text = "▶"
	selected_marker.position = Vector2(77, 52)
	selected_marker.size = Vector2(25, 30)
	selected_marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	selected_marker.add_theme_font_size_override("font_size", 21)
	selected_marker.add_theme_color_override("font_color", Color("ffd66c"))
	selected_marker.add_theme_color_override("font_outline_color", Color("34200c"))
	selected_marker.add_theme_constant_override("outline_size", 4)
	selected_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	selected_marker.hide()
	add_child(selected_marker)
	role_label = Label.new()
	role_label.position = Vector2(0, 108)
	role_label.size = Vector2(105, 30)
	role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	role_label.add_theme_font_size_override("font_size", 20)
	role_label.add_theme_color_override("font_color", Color("fff2ce"))
	role_label.add_theme_color_override("font_outline_color", Color("291808"))
	role_label.add_theme_constant_override("outline_size", 5)
	role_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(role_label)

func setup(character_id: String, display_name: String, role: String, _atlas: Texture2D) -> void:
	portrait.texture = load("res://assets/characters/kalaro/%s_peeking.png" % character_id) as Texture2D
	tooltip_text = "%s · %s" % [display_name, role]
	role_label.text = role

func set_cooldown(seconds: float) -> void:
	var cooling := seconds > 0.0
	(portrait.material as ShaderMaterial).set_shader_parameter("grayscale", cooling)
	countdown.text = str(ceili(seconds)) if cooling else ""

func set_selected(value: bool) -> void:
	if _selected == value:
		return
	_selected = value
	z_index = 1 if value else 0
	selected_marker.visible = value
	if _selection_tween != null and _selection_tween.is_valid():
		_selection_tween.kill()
	_selection_tween = create_tween().set_parallel(true)
	_selection_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_selection_tween.tween_property(portrait, "position:x", 84.0 if value else 112.0, 0.16)
	_selection_tween.tween_property(portrait, "scale", Vector2(1.05, 1.05) if value else Vector2.ONE, 0.16)
