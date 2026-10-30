class_name InteractiveTutorialOverlay
extends Control

# A non-blocking spotlight. It dims everything except one required target while
# leaving the target fully interactive underneath the overlay.

const DIM := Color(0.0, 0.0, 0.0, 0.64)
const GLOW := Color("ffe17d")

var spotlight_rect := Rect2()
var coachmark: PanelContainer
var title: Label
var instruction: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 52
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	coachmark = PanelContainer.new()
	coachmark.name = "TutorialCoachmark"
	coachmark.position = Vector2(600.0, 560.0)
	coachmark.size = Vector2(720.0, 118.0)
	coachmark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color("3a2116", 0.96)
	style.border_color = GLOW
	style.set_border_width_all(4)
	style.set_corner_radius_all(12)
	style.content_margin_left = 26.0
	style.content_margin_right = 26.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	coachmark.add_theme_stylebox_override("panel", style)
	add_child(coachmark)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 2)
	coachmark.add_child(content)
	title = Label.new()
	title.name = "TutorialStepTitle"
	title.add_theme_font_size_override("font_size", 21)
	title.add_theme_color_override("font_color", Color("f6d95e"))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(title)
	instruction = Label.new()
	instruction.name = "TutorialInstruction"
	instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instruction.add_theme_font_size_override("font_size", 29)
	instruction.add_theme_color_override("font_color", Color("fff5d6"))
	instruction.add_theme_color_override("font_outline_color", Color("2b1a10"))
	instruction.add_theme_constant_override("outline_size", 4)
	instruction.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(instruction)

func show_step(message: String, target_rect: Rect2, step_title: String = "GUIDE") -> void:
	spotlight_rect = target_rect.grow(18.0).intersection(Rect2(Vector2.ZERO, size))
	title.text = step_title
	instruction.text = message
	visible = true
	queue_redraw()

func clear_step() -> void:
	visible = false
	spotlight_rect = Rect2()
	title.text = ""
	instruction.text = ""
	queue_redraw()

func _draw() -> void:
	if spotlight_rect.size == Vector2.ZERO:
		return
	var viewport_rect := Rect2(Vector2.ZERO, size)
	draw_rect(Rect2(viewport_rect.position, Vector2(viewport_rect.size.x, spotlight_rect.position.y)), DIM)
	draw_rect(Rect2(Vector2(0.0, spotlight_rect.end.y), Vector2(viewport_rect.size.x, viewport_rect.end.y - spotlight_rect.end.y)), DIM)
	draw_rect(Rect2(Vector2(0.0, spotlight_rect.position.y), Vector2(spotlight_rect.position.x, spotlight_rect.size.y)), DIM)
	draw_rect(Rect2(Vector2(spotlight_rect.end.x, spotlight_rect.position.y), Vector2(viewport_rect.end.x - spotlight_rect.end.x, spotlight_rect.size.y)), DIM)
	draw_rect(spotlight_rect, GLOW, false, 5.0)
