class_name GameOverScreen
extends Control

# Dedicated game over overlay: dark red backdrop, a huge slammed-in "GAME OVER",
# Aling Cora standing in a dark band with a paper speech bubble, and a RETRY DAY button.
# It does NOT reuse the notebook summary panel, so it can never be mistaken for a shift summary.
#
# Usage (main.gd):
#   game_over_screen.present(COUNTER_ART.customer_portrait("aling_cora", PORTRAIT_ATLAS), campaign.day)
#   game_over_screen.retry_pressed.connect(_retry_current_day)
#   game_over_screen.dismiss()

signal retry_pressed

const RED := Color("#d94536")
const BAND := Color("#170d09")
const DIM := Color(0.09, 0.01, 0.01, 0.88)

const PORTRAIT_POS := Vector2(250.0, 365.0)
const PORTRAIT_SIZE := Vector2(450.0, 450.0)
const PANEL_POS := Vector2(740.0, 385.0)
const PANEL_W := 940.0
const BUTTON_POS := Vector2(740.0, 690.0)
const BUTTON_SIZE := Vector2(940.0, 110.0)

const SPEAKER := "ALING CORA"
const MESSAGE := "Naku, anak... umalis na ang mga suki natin, wala nang tiwala sa tindahan. Sige, ulitin natin ang araw na 'to, at mas bilisan natin ngayon."

var _dim: ColorRect
var _band_group: Control
var _title: Label
var _subtitle: Label
var _portrait: TextureRect
var _tail: Polygon2D
var _panel: PanelContainer
var _stat: Label
var _button: Button
var _tweens: Array[Tween] = []

func _init() -> void:
	size = StorefrontLayout.VIEWPORT_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_build()

func _build() -> void:
	var w := StorefrontLayout.VIEWPORT_SIZE.x

	# Oversized so it covers the screen on wide windows too.
	_dim = ColorRect.new()
	_dim.color = DIM
	_dim.position = Vector2(-1000.0, -600.0)
	_dim.size = StorefrontLayout.VIEWPORT_SIZE + Vector2(2000.0, 1200.0)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP     # blocks clicks on the store behind
	add_child(_dim)

	# Dark band the characters stand in, with red rules top and bottom.
	_band_group = Control.new()
	_band_group.position = Vector2(-1000.0, 340.0)
	_band_group.size = Vector2(w + 2000.0, 500.0)
	_band_group.pivot_offset = _band_group.size * 0.5
	_band_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_band_group)
	var band := ColorRect.new()
	band.color = BAND
	band.size = _band_group.size
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_band_group.add_child(band)
	for y in [0.0, 494.0]:
		var rule := ColorRect.new()
		rule.color = RED
		rule.position = Vector2(0.0, y)
		rule.size = Vector2(_band_group.size.x, 6.0)
		rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_band_group.add_child(rule)

	_title = KwentaStyle.make_label("GAME OVER", 190, RED)
	_title.add_theme_color_override("font_outline_color", KwentaStyle.INK)
	_title.add_theme_constant_override("outline_size", 20)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title.position = Vector2(0.0, 60.0)
	_title.size = Vector2(w, 220.0)
	_title.pivot_offset = _title.size * 0.5
	add_child(_title)

	_subtitle = KwentaStyle.make_label("NALUGI TAYO!", 54, KwentaStyle.PAPER)
	_subtitle.add_theme_color_override("font_outline_color", KwentaStyle.INK)
	_subtitle.add_theme_constant_override("outline_size", 10)
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.position = Vector2(0.0, 255.0)
	_subtitle.size = Vector2(w, 70.0)
	add_child(_subtitle)

	_portrait = TextureRect.new()
	_portrait.position = PORTRAIT_POS
	_portrait.size = PORTRAIT_SIZE
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait.modulate = Color(0.78, 0.7, 0.7)         # a little drained, she's disappointed
	add_child(_portrait)

	# Speech bubble tail pointing at Aling Cora (ink outline first, paper on top).
	var tail_edge := Polygon2D.new()
	tail_edge.color = KwentaStyle.INK
	tail_edge.polygon = PackedVector2Array([Vector2(PANEL_POS.x + 4.0, 520.0), Vector2(PANEL_POS.x - 46.0, 560.0), Vector2(PANEL_POS.x + 4.0, 600.0)])
	add_child(tail_edge)
	_tail = Polygon2D.new()
	_tail.color = KwentaStyle.PAPER
	_tail.polygon = PackedVector2Array([Vector2(PANEL_POS.x + 8.0, 530.0), Vector2(PANEL_POS.x - 34.0, 560.0), Vector2(PANEL_POS.x + 8.0, 590.0)])
	add_child(_tail)

	_panel = PanelContainer.new()
	_panel.position = PANEL_POS
	_panel.custom_minimum_size = Vector2(PANEL_W, 0.0)
	_panel.size = Vector2(PANEL_W, 270.0)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_theme_stylebox_override("panel", KwentaStyle.box(KwentaStyle.PAPER, KwentaStyle.INK, 40.0, 26.0, 14, 6, 10))
	add_child(_panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(column)
	column.add_child(KwentaStyle.make_label(SPEAKER, KwentaStyle.SIZE_CAPTION, KwentaStyle.INK_MUTED))
	var message := KwentaStyle.make_label(MESSAGE, 38, KwentaStyle.INK)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.custom_minimum_size = Vector2(PANEL_W - 80.0, 0.0)
	column.add_child(message)
	_stat = KwentaStyle.make_label("", KwentaStyle.SIZE_SMALL, Color("#a3281c"))
	column.add_child(_stat)

	_button = Button.new()
	_button.text = "RETRY DAY"
	_button.position = BUTTON_POS
	_button.size = BUTTON_SIZE
	KwentaStyle.style_button(_button, KwentaStyle.GOLD, KwentaStyle.SIZE_BUTTON)
	_button.pressed.connect(func() -> void: retry_pressed.emit())
	add_child(_button)

func present(portrait_tex: Texture2D, day: int) -> void:
	_kill_tweens()
	_portrait.texture = portrait_tex
	_stat.text = "ARAW %d  ·  SUKI METER: 0" % day
	visible = true
	_button.disabled = true

	# Start state for every element.
	_dim.modulate.a = 0.0
	_band_group.scale = Vector2(1.0, 0.0)
	_title.modulate = Color(1, 1, 1, 0)
	_title.scale = Vector2(2.6, 2.6)
	_title.position = Vector2(0.0, 60.0)
	_subtitle.modulate.a = 0.0
	_portrait.position = PORTRAIT_POS + Vector2(-220.0, 0.0)
	_portrait.modulate.a = 0.0
	for node in [_panel, _tail, _button]:
		node.modulate.a = 0.0
	_panel.position = PANEL_POS + Vector2(0.0, 30.0)

	# 1) the world goes dark, band opens
	var intro := _track(create_tween().set_parallel(true))
	intro.tween_property(_dim, "modulate:a", 1.0, 0.35)
	intro.tween_property(_band_group, "scale:y", 1.0, 0.3).set_delay(0.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# 2) GAME OVER slams in
	var slam := _track(create_tween().set_parallel(true))
	slam.tween_property(_title, "modulate:a", 1.0, 0.08).set_delay(0.3)
	slam.tween_property(_title, "scale", Vector2.ONE, 0.26).set_delay(0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	slam.tween_property(_subtitle, "modulate:a", 1.0, 0.3).set_delay(0.75)

	# screen-shake right when the slam lands
	var shake := _track(create_tween())
	shake.tween_interval(0.56)
	for dx in [16.0, -14.0, 10.0, -6.0, 0.0]:
		shake.tween_property(_title, "position:x", dx, 0.04)

	# 3) Aling Cora walks in, then her bubble
	var cast := _track(create_tween().set_parallel(true))
	cast.tween_property(_portrait, "position:x", PORTRAIT_POS.x, 0.45).set_delay(0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	cast.tween_property(_portrait, "modulate:a", 1.0, 0.3).set_delay(0.9)
	cast.tween_property(_panel, "modulate:a", 1.0, 0.3).set_delay(1.3)
	cast.tween_property(_panel, "position:y", PANEL_POS.y, 0.3).set_delay(1.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	cast.tween_property(_tail, "modulate:a", 1.0, 0.3).set_delay(1.3)
	cast.tween_property(_button, "modulate:a", 1.0, 0.3).set_delay(1.7)

	# 4) button becomes clickable only after the screen has landed (no accidental skip)
	var ready_tween := _track(create_tween())
	ready_tween.tween_interval(1.9)
	ready_tween.tween_callback(_on_ready_for_input)

func _on_ready_for_input() -> void:
	_button.disabled = false
	# idle: GAME OVER pulses, Aling Cora slowly droops/bobs
	var pulse := _track(create_tween().set_loops())
	pulse.tween_property(_title, "modulate", Color(1.0, 0.78, 0.74), 0.9).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(_title, "modulate", Color.WHITE, 0.9).set_trans(Tween.TRANS_SINE)
	var bob := _track(create_tween().set_loops())
	bob.tween_property(_portrait, "position:y", PORTRAIT_POS.y + 6.0, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	bob.tween_property(_portrait, "position:y", PORTRAIT_POS.y, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func dismiss() -> void:
	_kill_tweens()
	visible = false

func _track(tween: Tween) -> Tween:
	_tweens.append(tween)
	return tween

func _kill_tweens() -> void:
	for tween in _tweens:
		if tween != null and tween.is_valid():
			tween.kill()
	_tweens.clear()
