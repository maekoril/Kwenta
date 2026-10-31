class_name BriefingCard
extends Control

# Pre-shift briefing, built as its own screen instead of squeezing it into the notebook page.
#   header   : eyebrow, big title, day name
#   row 1    : TODAY'S FOCUS | SHIFT DETAILS   (two equal cards)
#   row 2    : SHELF with product chips (icon + name), wraps to a new line if needed
#   row 3    : optional daily goal ticket
#   footer   : OPEN STORE, a FIXED-SIZE button centered (never stretched across the page)
# Everything fits without scrolling. Main only calls show_briefing() and listens to start_pressed.

signal start_pressed

const CARD_SIZE := Vector2(1240.0, 900.0)
const INNER_WIDTH := 1084.0                      # CARD_SIZE.x - left margin 100 - right margin 56
const INFO_BODY_WIDTH := (INNER_WIDTH - 20.0) * 0.5 - 44.0
const SHELF_WIDTH := INNER_WIDTH - 44.0
const BUTTON_SIZE := Vector2(560.0, 104.0)
const CHIP_ICON := Vector2(56.0, 56.0)
const CARD_FILL := Color("#fbf1da")
const CARD_EDGE := Color("#8a6a45")
const GOAL_FILL := Color("#f3d98b")
const UNEARNED_MEDAL_SHADER: Shader = preload("res://shaders/unearned_medal.gdshader")

var _card: PanelContainer
var _eyebrow: Label
var _title: Label
var _subtitle: Label
var _focus_body: Label
var _shift_body: Label
var _shelf_card: PanelContainer
var _shelf_title: Label
var _chips: HFlowContainer
var _goal_title: Label
var _goal_reward: Label
var _button: Button
var _pulse: Tween
var _intro: Tween
var _briefing_sections: Array[Control] = []
var _summary_sections: VBoxContainer

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	z_index = 41
	resized.connect(_on_viewport_resized)
	_build()

func _build() -> void:
	_card = PanelContainer.new()
	_card.size = CARD_SIZE
	_card.mouse_filter = Control.MOUSE_FILTER_STOP
	var page := KwentaStyle.box(KwentaStyle.PAPER, KwentaStyle.INK, 56.0, 36.0, 12, 6, 12)
	page.content_margin_left = 100.0
	_card.add_theme_stylebox_override("panel", page)
	add_child(_card)
	var paper := NotebookPaper.new()   # ruled lines, red margin, punched holes (first child = behind content)
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(paper)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	_card.add_child(column)

	# --- header ---
	var header := VBoxContainer.new()
	header.add_theme_constant_override("separation", 2)
	column.add_child(header)
	_eyebrow = _centered(KwentaStyle.SIZE_CAPTION, KwentaStyle.INK_MUTED)
	_title = _centered(KwentaStyle.SIZE_H1 + 12, KwentaStyle.INK)
	_subtitle = _centered(KwentaStyle.SIZE_ROW_LABEL, KwentaStyle.INK_MUTED)
	header.add_child(_eyebrow)
	header.add_child(_title)
	header.add_child(_subtitle)
	column.add_child(_rule(4.0, KwentaStyle.INK))

	# --- row 1: focus | shift ---
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	column.add_child(row)
	_briefing_sections.append(row)
	var focus := _info_card("TODAY'S FOCUS")
	_focus_body = focus.get_meta("body")
	row.add_child(focus)
	var shift := _info_card("SHIFT DETAILS")
	_shift_body = shift.get_meta("body")
	row.add_child(shift)

	# --- row 2: shelf ---
	_shelf_card = _card_box()
	var shelf_column := VBoxContainer.new()
	shelf_column.add_theme_constant_override("separation", 10)
	_shelf_card.add_child(shelf_column)
	_shelf_title = KwentaStyle.make_label("", KwentaStyle.SIZE_CAPTION, KwentaStyle.INK_MUTED)
	shelf_column.add_child(_shelf_title)
	_chips = HFlowContainer.new()
	_chips.add_theme_constant_override("h_separation", 14)
	_chips.add_theme_constant_override("v_separation", 12)
	_chips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chips.custom_minimum_size = Vector2(SHELF_WIDTH, 0.0)
	shelf_column.add_child(_chips)
	column.add_child(_shelf_card)
	_briefing_sections.append(_shelf_card)

	# --- row 3: goal ticket ---
	var goal := PanelContainer.new()
	goal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	goal.add_theme_stylebox_override("panel", KwentaStyle.box(GOAL_FILL, KwentaStyle.INK, 22.0, 10.0, 10, 4, 5))
	var goal_row := HBoxContainer.new()
	goal_row.add_theme_constant_override("separation", 20)
	goal.add_child(goal_row)
	var goal_text := VBoxContainer.new()
	goal_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	goal_text.add_theme_constant_override("separation", 0)
	goal_text.add_child(KwentaStyle.make_label("OPTIONAL DAILY GOAL", KwentaStyle.SIZE_CAPTION, KwentaStyle.INK_MUTED))
	_goal_title = KwentaStyle.make_label("", KwentaStyle.SIZE_ROW_VALUE, KwentaStyle.INK)
	goal_text.add_child(_goal_title)
	goal_row.add_child(goal_text)
	var reward_box := VBoxContainer.new()
	reward_box.alignment = BoxContainer.ALIGNMENT_CENTER
	reward_box.add_theme_constant_override("separation", 0)
	var reward_caption := KwentaStyle.make_label("REWARD", KwentaStyle.SIZE_CAPTION, KwentaStyle.INK_MUTED)
	reward_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	reward_box.add_child(reward_caption)
	_goal_reward = KwentaStyle.make_label("", KwentaStyle.SIZE_ROW_LABEL, KwentaStyle.MONEY)
	_goal_reward.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	reward_box.add_child(_goal_reward)
	goal_row.add_child(reward_box)
	column.add_child(goal)
	_briefing_sections.append(goal)

	_summary_sections = VBoxContainer.new()
	_summary_sections.add_theme_constant_override("separation", 14)
	_summary_sections.visible = false
	column.add_child(_summary_sections)

	# --- footer: pushes the button to the bottom, centered, fixed size ---
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(spacer)
	var footer := CenterContainer.new()
	column.add_child(footer)
	_button = Button.new()
	_button.text = "OPEN STORE  >>"
	_button.custom_minimum_size = BUTTON_SIZE
	_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	KwentaStyle.style_button(_button, KwentaStyle.GOLD, KwentaStyle.SIZE_BUTTON)
	_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_button.resized.connect(func() -> void: _button.pivot_offset = _button.size * 0.5)
	_button.pressed.connect(func() -> void: start_pressed.emit())
	footer.add_child(_button)

func show_briefing(briefing: DayBriefing, viewport_size: Vector2) -> void:
	for section in _briefing_sections:
		section.visible = true
	_summary_sections.visible = false
	_button.text = "OPEN STORE  >>"
	_eyebrow.text = briefing.eyebrow
	_title.text = briefing.title
	_subtitle.text = briefing.heading if briefing.title != briefing.heading else ""
	_subtitle.visible = not _subtitle.text.is_empty()
	_focus_body.text = briefing.focus
	_shift_body.text = briefing.shift_detail
	_goal_title.text = briefing.goal_title
	_goal_reward.text = briefing.goal_reward
	_fill_shelf(briefing)

	size = viewport_size
	visible = true
	_card.modulate.a = 0.0
	_settle.call_deferred(viewport_size)

func show_summary(title: String, summary: String, viewport_size: Vector2, reward_day: int = 0, reward_earned: bool = true) -> void:
	for section in _briefing_sections:
		section.visible = false
	for child in _summary_sections.get_children():
		_summary_sections.remove_child(child)
		child.queue_free()
	_eyebrow.text = "KUWADERNO"
	_title.text = title.get_slice(" \u00b7 ", 0)
	_subtitle.text = title.get_slice(" \u00b7 ", 1) if title.contains(" \u00b7 ") else ""
	_subtitle.visible = not _subtitle.text.is_empty()
	_button.text = "CONTINUE  >>"
	var results_row := HBoxContainer.new()
	results_row.add_theme_constant_override("separation", 20)
	_summary_sections.add_child(results_row)
	var goal_panel: PanelContainer
	for section_text in summary.split("\n\n", false):
		var lines := section_text.split("\n", false, 1)
		var panel := _card_box()
		var content_row := HBoxContainer.new()
		content_row.add_theme_constant_override("separation", 20)
		panel.add_child(content_row)
		var box := VBoxContainer.new()
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.add_theme_constant_override("separation", 8)
		content_row.add_child(box)
		box.add_child(KwentaStyle.make_label(lines[0], KwentaStyle.SIZE_CAPTION, KwentaStyle.INK_MUTED))
		if lines.size() > 1:
			var body_size := KwentaStyle.SIZE_ROW_LABEL if lines[0].begins_with("DAILY GOAL") else KwentaStyle.SIZE_ROW_VALUE
			var body := KwentaStyle.make_label(lines[1], body_size, KwentaStyle.INK)
			body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			box.add_child(body)
		if lines[0].begins_with("DAILY GOAL"):
			goal_panel = panel
			if reward_day >= 1 and reward_day <= 7:
				var medal := TextureRect.new()
				medal.name = "DailyGoalMedal"
				medal.texture = load("res://assets/sprites/ui/daily_medals/day_%d.png" % reward_day) as Texture2D
				medal.custom_minimum_size = Vector2(132, 132)
				medal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				medal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				medal.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				medal.mouse_filter = Control.MOUSE_FILTER_IGNORE
				content_row.add_child(medal)
				if reward_earned:
					_animate_medal.call_deferred(medal)
				else:
					var grayscale := ShaderMaterial.new()
					grayscale.shader = UNEARNED_MEDAL_SHADER
					medal.material = grayscale
		else:
			panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			results_row.add_child(panel)
	if goal_panel != null:
		_summary_sections.add_child(goal_panel)
	_summary_sections.visible = true
	size = viewport_size
	visible = true
	_card.modulate.a = 0.0
	_settle.call_deferred(viewport_size)

func _animate_medal(medal: TextureRect) -> void:
	await get_tree().process_frame
	if not is_instance_valid(medal) or not visible:
		return
	medal.pivot_offset = medal.size * 0.5
	medal.scale = Vector2.ONE * 0.4
	medal.modulate.a = 0.0
	var pop := create_tween()
	pop.tween_interval(0.35)
	pop.tween_property(medal, "modulate:a", 1.0, 0.12)
	pop.parallel().tween_property(medal, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _settle(viewport_size: Vector2, play_intro: bool = true) -> void:
	# Let containers recalculate their minimum sizes after switching card contents.
	await get_tree().process_frame
	if not is_inside_tree() or not visible:
		return
	_card.reset_size()
	_card.size = CARD_SIZE
	await get_tree().process_frame
	if not is_inside_tree() or not visible:
		return
	var fit := minf(1.0, minf((viewport_size.x - 80.0) / _card.size.x, (viewport_size.y - 80.0) / _card.size.y))
	_card.position = ((viewport_size - _card.size) * 0.5).round()
	if play_intro:
		_play_intro(fit)
	else:
		if _intro != null and _intro.is_valid():
			_intro.kill()
		_card.scale = Vector2.ONE * fit
		_card.modulate.a = 1.0

func _on_viewport_resized() -> void:
	if visible:
		_settle.call_deferred(size, false)

func hide_briefing() -> void:
	visible = false
	if _pulse != null and _pulse.is_valid():
		_pulse.kill()
	if _intro != null and _intro.is_valid():
		_intro.kill()

# --- helpers ---

func _fill_shelf(briefing: DayBriefing) -> void:
	for child in _chips.get_children():
		_chips.remove_child(child)
		child.queue_free()
	_shelf_card.visible = not briefing.unlocked_products.is_empty()
	_shelf_title.text = briefing.product_section_title
	for product_value in briefing.unlocked_products:
		var product := product_value as ProductData
		if product != null:
			_chips.add_child(_chip(product))

func _chip(product: ProductData) -> Control:
	var chip := PanelContainer.new()
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_theme_stylebox_override("panel", KwentaStyle.box(KwentaStyle.PAPER_DARK, KwentaStyle.INK_MUTED, 12.0, 6.0, 8, 3, 3))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	chip.add_child(row)
	var icon := TextureRect.new()
	icon.texture = product.single_unit_texture
	icon.custom_minimum_size = CHIP_ICON
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	var name_label := KwentaStyle.make_label(product.display_name, KwentaStyle.SIZE_ROW_LABEL, KwentaStyle.INK)
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(name_label)
	return chip

func _info_card(tag_text: String) -> PanelContainer:
	var panel := _card_box()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	box.add_child(KwentaStyle.make_label(tag_text, KwentaStyle.SIZE_CAPTION, KwentaStyle.INK_MUTED))
	var body := KwentaStyle.make_label("", KwentaStyle.SIZE_ROW_VALUE, KwentaStyle.INK)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(INFO_BODY_WIDTH, 96.0)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(body)
	panel.set_meta("body", body)
	return panel

func _card_box() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", KwentaStyle.box(CARD_FILL, CARD_EDGE, 22.0, 14.0, 10, 3, 4))
	return panel

func _centered(font_size: int, color: Color) -> Label:
	var label := KwentaStyle.make_label("", font_size, color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label

func _rule(height: float, color: Color) -> ColorRect:
	var rule := ColorRect.new()
	rule.color = color
	rule.custom_minimum_size = Vector2(0.0, height)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rule

func _play_intro(fit: float = 1.0) -> void:
	if _intro != null and _intro.is_valid():
		_intro.kill()
	if _pulse != null and _pulse.is_valid():
		_pulse.kill()
	_card.pivot_offset = _card.size * 0.5
	_card.scale = Vector2.ONE * fit * 0.94
	_card.modulate.a = 0.0
	_intro = create_tween().set_parallel(true)
	_intro.tween_property(_card, "scale", Vector2.ONE * fit, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_intro.tween_property(_card, "modulate:a", 1.0, 0.16)
	# Gentle "press me" pulse once the card has landed.
	_button.scale = Vector2.ONE
	_button.pivot_offset = _button.size * 0.5
	_pulse = create_tween().set_loops()
	_pulse.tween_interval(0.6)
	_pulse.tween_property(_button, "scale", Vector2(1.04, 1.04), 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse.tween_property(_button, "scale", Vector2.ONE, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
