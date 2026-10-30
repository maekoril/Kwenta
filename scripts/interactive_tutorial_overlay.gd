class_name InteractiveTutorialOverlay
extends Control

# A non-blocking spotlight. It dims everything except one required target while
# leaving the target fully interactive underneath the overlay.

signal next_pressed
signal skip_pressed

const DIM := Color(0.06, 0.035, 0.02, 0.48)
const GLOW := Color("ffe17d")

var spotlight_rect := Rect2()
var coachmark: PanelContainer
var title: Label
var instruction: Label
var next_button: Button
var skip_button: Button
var action_row: HBoxContainer
var arrow_from := Vector2.ZERO
var arrow_to := Vector2.ZERO
var arrow_target_rect := Rect2()
var arrow_visible := false
var glow_time := 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 52
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	coachmark = PanelContainer.new()
	coachmark.name = "TutorialCoachmark"
	coachmark.custom_minimum_size = Vector2(650.0, 0.0)
	coachmark.size = Vector2(650.0, 180.0)
	coachmark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := KwentaStyle.box(KwentaStyle.PAPER, KwentaStyle.INK, 26.0, 18.0, 12, 4, 6)
	coachmark.add_theme_stylebox_override("panel", style)
	add_child(coachmark)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	coachmark.add_child(content)
	title = Label.new()
	title.name = "TutorialStepTitle"
	KwentaStyle.apply_font(title)
	title.add_theme_font_size_override("font_size", 27)
	title.add_theme_color_override("font_color", KwentaStyle.INK_MUTED)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(title)
	instruction = Label.new()
	instruction.name = "TutorialInstruction"
	instruction.custom_minimum_size.x = 590.0
	instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	instruction.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	KwentaStyle.apply_font(instruction)
	instruction.add_theme_font_size_override("font_size", 32)
	instruction.add_theme_color_override("font_color", KwentaStyle.INK)
	instruction.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(instruction)
	action_row = HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 16)
	content.add_child(action_row)
	skip_button = Button.new()
	skip_button.text = "SKIP TUTORIAL"
	skip_button.custom_minimum_size = Vector2(250.0, 60.0)
	KwentaStyle.style_button(skip_button, KwentaStyle.PAPER_DARK, 24)
	skip_button.pressed.connect(func() -> void: skip_pressed.emit())
	skip_button.visible = false
	action_row.add_child(skip_button)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_row.add_child(spacer)
	next_button = Button.new()
	next_button.text = "NEXT  >>"
	next_button.custom_minimum_size = Vector2(230.0, 60.0)
	next_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	KwentaStyle.style_button(next_button, KwentaStyle.GOLD, KwentaStyle.SIZE_ROW_LABEL)
	next_button.pressed.connect(func() -> void: next_pressed.emit())
	next_button.visible = false
	action_row.add_child(next_button)

func show_step(message: String, target_rect: Rect2, step_title: String = "GUIDE") -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	next_button.visible = false
	skip_button.visible = false
	action_row.visible = false
	arrow_visible = false
	spotlight_rect = target_rect.grow(18.0).intersection(Rect2(Vector2.ZERO, size))
	title.text = step_title
	instruction.text = message
	visible = true
	_position_coachmark()
	queue_redraw()

func show_info_step(message: String, target_rect: Rect2, step_title: String, is_last: bool = false) -> void:
	show_step(message, target_rect, step_title)
	mouse_filter = Control.MOUSE_FILTER_STOP
	next_button.text = "LET'S START  >>" if is_last else "NEXT  >>"
	next_button.visible = true
	skip_button.visible = true
	action_row.visible = true
	_position_coachmark()
	_reposition_after_layout()

func show_skip() -> void:
	skip_button.visible = true
	action_row.visible = true
	_position_coachmark()
	_reposition_after_layout()

func show_drag_arrow(from_rect: Rect2, to_rect: Rect2) -> void:
	arrow_from = from_rect.get_center()
	arrow_to = to_rect.get_center()
	arrow_target_rect = to_rect
	arrow_visible = true
	_position_coachmark()
	_reposition_after_layout()
	queue_redraw()

func _reposition_after_layout() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if visible:
		_position_coachmark()

func _position_coachmark() -> void:
	# Put the card on the opposite side of the highlighted item, within the canvas.
	coachmark.reset_size()
	var card_height := maxf(coachmark.get_combined_minimum_size().y, 200.0)
	if arrow_visible:
		# Keep the whole card outside the highlighted product and drag path.
		var path_left := minf(spotlight_rect.position.x, arrow_target_rect.position.x)
		var path_right := maxf(spotlight_rect.end.x, arrow_target_rect.end.x)
		var right_x := path_right + 40.0
		var left_x := path_left - coachmark.size.x - 40.0
		var side_x := right_x if right_x + coachmark.size.x <= size.x - 30.0 else left_x
		side_x = clampf(side_x, 30.0, size.x - coachmark.size.x - 30.0)
		var side_y := clampf((arrow_from.y + arrow_to.y) * 0.5 - card_height * 0.5, 30.0, size.y - card_height - 30.0)
		coachmark.position = Vector2(side_x, side_y)
		return
	var x := clampf(spotlight_rect.get_center().x - 325.0, 30.0, size.x - 680.0)
	var y := spotlight_rect.end.y + 42.0
	if y + card_height > size.y - 30.0:
		y = maxf(30.0, spotlight_rect.position.y - card_height - 42.0)
	coachmark.position = Vector2(x, y)

func _process(delta: float) -> void:
	if visible:
		glow_time += delta
		queue_redraw()

func clear_step() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	next_button.visible = false
	skip_button.visible = false
	action_row.visible = false
	arrow_visible = false
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
	var glow_alpha := 0.6 + 0.35 * (0.5 + 0.5 * sin(glow_time * 3.0))
	draw_rect(spotlight_rect.grow(5.0), Color(GLOW, glow_alpha * 0.25), false, 9.0)
	draw_rect(spotlight_rect, Color(GLOW, glow_alpha), false, 4.0)
	if not arrow_visible and spotlight_rect.end.y < coachmark.position.y:
		var pointer_x := clampf(spotlight_rect.get_center().x, coachmark.position.x + 24.0, coachmark.position.x + coachmark.size.x - 24.0)
		var pointer_y := coachmark.position.y
		draw_colored_polygon(PackedVector2Array([Vector2(pointer_x, pointer_y - 20.0), Vector2(pointer_x - 14.0, pointer_y), Vector2(pointer_x + 14.0, pointer_y)]), KwentaStyle.INK)
	if arrow_visible:
		var direction := (arrow_to - arrow_from).normalized()
		var start := arrow_from + direction * 35.0
		var finish := arrow_to - direction * 70.0
		var pulse := 0.7 + 0.3 * (0.5 + 0.5 * sin(glow_time * 4.0))
		draw_line(start, finish, Color(GLOW, pulse), 8.0, true)
		var side := Vector2(-direction.y, direction.x)
		draw_colored_polygon(PackedVector2Array([finish + direction * 18.0, finish - direction * 18.0 + side * 16.0, finish - direction * 18.0 - side * 16.0]), Color(GLOW, pulse))
