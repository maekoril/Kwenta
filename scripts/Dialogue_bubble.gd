# dialogue_bubble.gd  (Godot 4.x)  -- v3, sized for Kwenta's 1920x1080 viewport
#
# Save as res://scripts/dialogue_bubble.gd   (replaces the v2 file)
#
# It builds itself in code, like the rest of main.gd, and is driven by signals
# so it plugs into the existing story state machine.
#
#   bubble.show_beat(speaker, text, portrait_texture, portrait_id)
#       One line. When the player taps through it, `advanced` is emitted.
#
#   bubble.ask(speaker, prompt, ["option A", "option B"], portrait_texture, portrait_id)
#       A question with tappable answer bubbles. Emits `choice_made(index)`.
#       With speaker "Narrator" the question is the GAME asking the player: a centered banner
#       with a "PILIIN" tab, attached to nobody. The answers are what the character could say:
#       cream bubbles with tails pointing at the character's portrait.
#
#   bubble.title_card("PROLOGUE · ANG SUSI")
#       Chapter card; `await` it. A tap skips it.
#
#   bubble.close()
#       Fades everything out. Call it when the beats are over.
#
# How a line is drawn is decided by the SPEAKER, not by the portrait:
#   speaker is a character + portrait -> cream speech bubble beside the portrait, tail pointing at it
#   speaker is "Narrator" + portrait   -> dark caption beside the portrait (scene-setting, nobody is "talking")
#   speaker is "Narrator", no portrait -> dark caption at the bottom
# Tonyo (any "tonyo_*" expression) stands on the right, everyone else on the left.
# Expressions like "aling_cora_reading" count as the same character as "aling_cora",
# so a change of expression swaps the picture without re-sliding the character in.
#
# Tap anywhere: first tap finishes the typing, second tap continues.
# Enter/Space also work. During a question, only the answer bubbles respond.
class_name DialogueBubble
extends Control

signal advanced
signal choice_made(index: int)
signal typing_blip
signal conversation_started
signal conversation_finished
signal speech_started
signal _title_done

# --- Look (all values are for 1920x1080). Reuse these for the HUD later. ---
const PAPER := Color("#f6e7c8")
const INK := Color("#2b1a10")
const GOLD := Color("#e0a33a")
const CAPTION_BG := Color("#1c120c", 0.94)
const CAPTION_INK := Color("#f6e7c8")
const TITLE_INK := Color("#ffe1a7")
const FONT_PATH := "res://assets/fonts/PixelifySans-Regular.ttf"  # change to the font you add
const FONT_SIZE := 40
const NAME_SIZE := 32
const TITLE_SIZE := 84
const OPTION_SIZE := 36
const BORDER_W := 6
const CORNER := 14
const CHARS_PER_SEC := 50.0
const DIM_ALPHA := 0.3
const PROTAGONIST_KEY := "tonyo"
# Character ids used in the story data. A portrait id is "<character>" or "<character>_<expression>".
# Add new characters here; an unlisted id still works, it is just treated as its own character.
const CHARACTERS: Array[String] = ["tonyo", "aling_cora", "mang_berting", "aling_nena", "jun_jun", "mikay", "bogs", "bea", "paolo", "kuya_dodong"]
const PORTRAIT_SIZE := Vector2(360, 540)
const PORTRAIT_MARGIN := 110.0
const BUBBLE_W := 1100.0
const CAPTION_W := 1500.0
const TAIL_SIZE := Vector2(40, 54)
const OPTION_H := 84.0
const OPTION_GAP := 14.0
const CHOICE_GAP_TOP := 26.0
const PROMPT_TAG := "PILIIN"            # tab on the question banner
const PROMPT_W := 1200.0
const PROMPT_Y := 240.0                 # top of the question banner
const OPTION_W := 760.0                 # width of answer bubbles next to the portrait
const OPTION_TAIL := Vector2(30, 40)
const HUD_CLEARANCE := 110.0
const SCREEN_MARGIN := 60.0

var _dim: ColorRect
var _portrait: TextureRect
var _group: Control
var _panel: PanelContainer
var _tail: Tail
var _tag: PanelContainer
var _tag_label: Label
var _text: RichTextLabel
var _hint: Polygon2D
var _choices: VBoxContainer
var _title_label: Label
var _font: Font

var _portrait_key := ""
var _typing := false
var _busy := false
var _choosing := false
var _choices_ready := false
var _last_blip_character := 0
var _conversation_active := false
var _type_tween: Tween
var _bob_tween: Tween
var _hint_tween: Tween
var _breath_tween: Tween
var _portrait_tween: Tween
var _close_tween: Tween
var _title_tween: Tween


# The little triangle that turns a box into a speech bubble.
class Tail extends Control:
	var fill := Color.WHITE
	var ink := Color.BLACK
	var border := 6.0
	var points_right := false   # false: sits on the bubble's left edge, pointing left

	func _draw() -> void:
		var a: Vector2
		var b: Vector2
		var tip: Vector2
		if points_right:
			a = Vector2(-border, 0.0)
			b = Vector2(-border, size.y)
			tip = Vector2(size.x, size.y * 0.7)
		else:
			a = Vector2(size.x + border, 0.0)
			b = Vector2(size.x + border, size.y)
			tip = Vector2(0.0, size.y * 0.7)
		# Base starts inside the panel's border so the opening looks seamless.
		draw_colored_polygon(PackedVector2Array([a, b, tip]), fill)
		draw_polyline(PackedVector2Array([a, tip, b]), ink, border)


func _ready() -> void:
	if size == Vector2.ZERO:
		size = get_viewport_rect().size
	mouse_filter = Control.MOUSE_FILTER_STOP   # swallow taps so nothing behind gets pressed
	visible = false
	if ResourceLoader.exists(FONT_PATH):
		_font = load(FONT_PATH)

	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0)
	_dim.size = size
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dim)

	# The standing character. Portraits are not pixel art, so use linear filtering like main.gd does.
	_portrait = TextureRect.new()
	_portrait.custom_minimum_size = PORTRAIT_SIZE
	_portrait.size = PORTRAIT_SIZE
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait.visible = false
	add_child(_portrait)

	# Bubble pieces that pop and float together.
	_group = Control.new()
	_group.size = size
	_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_group)

	_panel = PanelContainer.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_group.add_child(_panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(v)

	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.fit_content = true
	_text.scroll_active = false
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_text.add_theme_font_size_override("normal_font_size", FONT_SIZE)
	if _font:
		_text.add_theme_font_override("normal_font", _font)
	v.add_child(_text)

	# Bobbing arrow instead of a CONTINUE button.
	var hint_holder := Control.new()
	hint_holder.custom_minimum_size = Vector2(42, 30)
	hint_holder.size_flags_horizontal = Control.SIZE_SHRINK_END
	hint_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(hint_holder)
	_hint = Polygon2D.new()
	_hint.polygon = PackedVector2Array([Vector2(6, 3), Vector2(36, 3), Vector2(21, 21)])
	hint_holder.add_child(_hint)

	_tail = Tail.new()
	_tail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_group.add_child(_tail)

	# Name tag that sticks out of the bubble's top-left corner.
	_tag = PanelContainer.new()
	_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ts := _box_style(GOLD, INK)
	ts.content_margin_top = 6
	ts.content_margin_bottom = 6
	ts.content_margin_left = 22
	ts.content_margin_right = 22
	ts.shadow_offset = Vector2(0, 5)
	_tag.add_theme_stylebox_override("panel", ts)
	_tag_label = Label.new()
	_tag_label.add_theme_color_override("font_color", INK)
	_tag_label.add_theme_font_size_override("font_size", NAME_SIZE)
	if _font:
		_tag_label.add_theme_font_override("font", _font)
	_tag_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tag.add_child(_tag_label)
	_group.add_child(_tag)

	# Answer bubbles for questions. Separate from _group so they don't float around under a thumb.
	_choices = VBoxContainer.new()
	_choices.add_theme_constant_override("separation", int(OPTION_GAP))
	_choices.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_choices.visible = false
	add_child(_choices)

	# Chapter card text.
	_title_label = Label.new()
	_title_label.size = size
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", TITLE_SIZE)
	_title_label.add_theme_color_override("font_color", TITLE_INK)
	_title_label.add_theme_color_override("font_outline_color", INK)
	_title_label.add_theme_constant_override("outline_size", 12)
	if _font:
		_title_label.add_theme_font_override("font", _font)
	_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title_label.visible = false
	add_child(_title_label)


func _box_style(bg: Color, edge: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = edge
	sb.set_border_width_all(BORDER_W)
	sb.set_corner_radius_all(CORNER)
	sb.anti_aliasing = false                    # crisp, pixel-style corners
	sb.content_margin_left = 32
	sb.content_margin_right = 32
	sb.content_margin_top = 22
	sb.content_margin_bottom = 14
	sb.shadow_color = Color(0, 0, 0, 0.4)       # hard offset shadow, no blur
	sb.shadow_size = 0
	sb.shadow_offset = Vector2(0, 9)
	return sb


func _choice_style(bg: Color) -> StyleBoxFlat:
	var sb := _box_style(bg, INK)
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	sb.shadow_offset = Vector2(0, 7)
	return sb


func _make_choice_button(label: String, index: int, tail_dir: int = 0) -> Button:
	var b := Button.new()
	b.text = label
	b.custom_minimum_size = Vector2(0.0, OPTION_H)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", OPTION_SIZE)
	if _font:
		b.add_theme_font_override("font", _font)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color", "font_focus_color"]:
		b.add_theme_color_override(c, INK)
	var normal := _choice_style(PAPER)
	b.add_theme_stylebox_override("normal", normal)
	# Every state looks the same (paper) so the speech-bubble tail always matches.
	# Feedback is a small hover pop and a gold flash once picked.
	b.add_theme_stylebox_override("hover", normal)
	b.add_theme_stylebox_override("pressed", normal)
	b.add_theme_stylebox_override("disabled", normal)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS   # fire on touch-down, feels snappier
	b.pressed.connect(_on_choice_pressed.bind(index))
	b.mouse_entered.connect(_on_choice_hover.bind(b, true))
	b.mouse_exited.connect(_on_choice_hover.bind(b, false))
	if tail_dir != 0:
		# Makes the answer read as a speech bubble pointing at the character.
		var tail := Tail.new()
		tail.size = OPTION_TAIL
		tail.fill = PAPER
		tail.ink = INK
		tail.border = float(BORDER_W)
		tail.points_right = tail_dir > 0
		tail.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(tail)
		b.set_meta("tail", tail)
		b.resized.connect(_place_option_tail.bind(b, tail))
	b.modulate.a = 0.0     # revealed one by one once the question has finished typing
	b.disabled = true
	return b


func _place_option_tail(b: Button, tail: Tail) -> void:
	var x := b.size.x if tail.points_right else -tail.size.x
	tail.position = Vector2(x, (b.size.y - tail.size.y) * 0.5)


func _on_choice_hover(b: Button, entered: bool) -> void:
	if not _choices_ready:
		return
	create_tween().tween_property(b, "scale", Vector2.ONE * (1.04 if entered else 1.0), 0.1)


# ---------------------------------------------------------------- public API

# Fire-and-forget: connect to `advanced` to know when the player moved on.
func show_beat(speaker: String, line: String, portrait_tex: Texture2D = null, portrait_key: String = "") -> void:
	_present(speaker, line, portrait_tex, portrait_key)


# Awaitable version: `await bubble.say("Nanay", "Tonyo!", tex, "nanay")`
func say(speaker: String, line: String, portrait_tex: Texture2D = null, portrait_key: String = "") -> void:
	_present(speaker, line, portrait_tex, portrait_key)
	await advanced


# A question with answer bubbles. Connect to `choice_made(index)`; index is the position in `options`.
func ask(speaker: String, prompt: String, options: Array, portrait_tex: Texture2D = null, portrait_key: String = "") -> void:
	_present(speaker, prompt, portrait_tex, portrait_key, options)


func title_card(text: String) -> void:
	_end_conversation()
	if _close_tween:
		_close_tween.kill()
	_set_portrait(null, "", false)
	_group.modulate.a = 0.0
	_title_label.text = text
	_title_label.modulate.a = 0.0
	_title_label.visible = true
	visible = true
	_title_tween = create_tween().set_parallel(true)
	_title_tween.tween_property(_dim, "color:a", 0.55, 0.3)
	_title_tween.tween_property(_title_label, "modulate:a", 1.0, 0.4)
	_title_tween.chain().tween_interval(1.2)
	_title_tween.chain().tween_property(_title_label, "modulate:a", 0.0, 0.35)
	_title_tween.finished.connect(_end_title)
	await _title_done


func close() -> void:
	_end_conversation()
	if not visible:
		return
	for t in [_bob_tween, _hint_tween, _breath_tween, _portrait_tween]:
		if t:
			t.kill()
	_portrait_key = ""
	_choosing = false
	_choices_ready = false
	_close_tween = create_tween().set_parallel(true)
	_close_tween.tween_property(_dim, "color:a", 0.0, 0.2)
	_close_tween.tween_property(_portrait, "modulate:a", 0.0, 0.2)
	_close_tween.tween_property(_group, "modulate:a", 0.0, 0.1)
	_close_tween.tween_property(_choices, "modulate:a", 0.0, 0.1)
	_close_tween.chain().tween_callback(_finish_close)


# ---------------------------------------------------------------- internals

func _present(speaker: String, line: String, portrait_tex: Texture2D, portrait_key: String, options: Array = []) -> void:
	_busy = true
	if _close_tween:
		_close_tween.kill()
	_title_label.visible = false

	var narration := speaker == "" or speaker.to_lower() == "narrator"
	var with_portrait := portrait_tex != null
	var is_speech := with_portrait and not narration     # speech bubble with a tail
	var char_key := _character_of(portrait_key)
	var right_side := with_portrait and char_key == PROTAGONIST_KEY
	var is_prompt := narration and not options.is_empty()   # the game asking the player
	var show_tag := (not narration) or is_prompt
	var tail_dir := 0
	if is_prompt and with_portrait:
		tail_dir = 1 if right_side else -1

	# --- reset / build answer bubbles ---
	_choices_ready = false
	_choosing = not options.is_empty()
	for c in _choices.get_children():
		_choices.remove_child(c)
		c.queue_free()
	_choices.modulate.a = 1.0
	_choices.visible = _choosing
	for i in options.size():
		_choices.add_child(_make_choice_button(str(options[i]), i, tail_dir))

	# --- style for this line ---
	_panel.add_theme_stylebox_override("panel", _box_style(
		PAPER if is_speech else CAPTION_BG,
		INK if is_speech else GOLD))
	var ink := INK if is_speech else CAPTION_INK
	_text.add_theme_color_override("default_color", ink)
	_text.text = ("[center]%s[/center]" % line) if is_prompt else line   # BBCode works here: [color=red], [i]...
	_text.visible_ratio = 0.0
	_tag.visible = show_tag
	_tag_label.text = PROMPT_TAG if is_prompt else speaker
	_tail.visible = is_speech
	_tail.points_right = right_side
	_tail.fill = PAPER
	_tail.ink = INK
	_tail.border = float(BORDER_W)
	_tail.queue_redraw()
	_hint.visible = false
	_hint.get_parent().visible = not _choosing   # no empty arrow row under a question
	_hint.color = ink
	_set_portrait(portrait_tex, char_key, right_side)

	visible = true
	_begin_conversation()
	if not narration:
		speech_started.emit()
	if not is_equal_approx(_dim.color.a, DIM_ALPHA):
		create_tween().tween_property(_dim, "color:a", DIM_ALPHA, 0.25)
	_group.modulate.a = 0.0

	# --- size the bubble; wait for the text to wrap so we know its height ---
	var vp := size
	var w: float
	if is_prompt:
		w = minf(PROMPT_W, vp.x - 160.0)
	elif with_portrait:
		var used := PORTRAIT_MARGIN + PORTRAIT_SIZE.x + TAIL_SIZE.x + 12.0
		w = minf(BUBBLE_W, vp.x - used - 100.0)
	else:
		w = minf(CAPTION_W, vp.x - 160.0)
	_panel.custom_minimum_size = Vector2(w, 0.0)
	_panel.reset_size()
	var cw := minf(OPTION_W, w) if is_prompt else w
	_choices.custom_minimum_size = Vector2(cw, 0.0)
	_choices.reset_size()
	await get_tree().process_frame
	await get_tree().process_frame
	_panel.reset_size()
	_choices.reset_size()
	var h := _panel.size.y
	var stack_h := h
	if _choosing:
		stack_h += CHOICE_GAP_TOP + _choices.size.y

	# --- place it ---
	var p := Vector2.ZERO
	var pivot := Vector2.ZERO
	var face_y := vp.y - PORTRAIT_SIZE.y + 170.0
	var edge := PORTRAIT_MARGIN + PORTRAIT_SIZE.x + TAIL_SIZE.x + 12.0
	if is_prompt:
		# Question banner: centered and high, attached to nobody.
		p = Vector2((vp.x - w) * 0.5, PROMPT_Y)
		pivot = p + Vector2(w * 0.5, h)
	elif with_portrait:
		p.x = (vp.x - edge - w) if right_side else edge
		p.y = clampf(face_y - h * 0.4, HUD_CLEARANCE, vp.y - stack_h - SCREEN_MARGIN)
		_tail.size = TAIL_SIZE
		var ty := clampf(face_y - TAIL_SIZE.y * 0.5, p.y + 30.0, p.y + h - 30.0 - TAIL_SIZE.y)
		if right_side:
			_tail.position = Vector2(p.x + w, ty)
			pivot = _tail.position + Vector2(TAIL_SIZE.x, TAIL_SIZE.y * 0.7)
		else:
			_tail.position = Vector2(p.x - TAIL_SIZE.x, ty)
			pivot = _tail.position + Vector2(0.0, TAIL_SIZE.y * 0.7)
		if not is_speech:
			pivot = p + Vector2(w * 0.5, h)
	else:
		p = Vector2((vp.x - w) * 0.5, vp.y - stack_h - 70.0)
		pivot = p + Vector2(w * 0.5, h)
	_panel.position = p
	_tag.reset_size()
	if is_prompt:
		# "PILIIN" tab centered on the banner (a speaker's name tag sits at the corner instead).
		_tag.position = p + Vector2((w - _tag.size.x) * 0.5, -_tag.size.y * 0.55)
		# Answers stand beside the character, level with their face, away from the banner.
		var oh := _choices.size.y
		var cx := (vp.x - edge - cw) if right_side else edge
		if not with_portrait:
			cx = (vp.x - cw) * 0.5
		var cy := clampf(face_y - oh * 0.5, p.y + h + 70.0, vp.y - SCREEN_MARGIN - oh)
		_choices.position = Vector2(cx, cy)
	else:
		_tag.position = p + Vector2(28.0, -_tag.size.y * 0.55)
		_choices.position = Vector2(p.x, p.y + h + CHOICE_GAP_TOP)

	# --- pop in, growing out of the tail tip (or the caption's bottom edge) ---
	_group.pivot_offset = pivot
	_group.scale = Vector2(0.8, 0.8)
	var t := create_tween().set_parallel(true)
	t.tween_property(_group, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(_group, "modulate:a", 1.0, 0.12)
	_start_bob()

	# --- typewriter ---
	_typing = true
	_busy = false
	_last_blip_character = 0
	var dur := maxf(0.2, _text.get_total_character_count() / CHARS_PER_SEC)
	_type_tween = create_tween()
	_type_tween.tween_method(_reveal_text, 0.0, 1.0, dur)
	_type_tween.finished.connect(_finish_typing)

func _reveal_text(progress: float) -> void:
	_text.visible_ratio = progress
	var revealed_characters := int(floor(float(_text.get_total_character_count()) * progress))
	if revealed_characters >= _last_blip_character + 3:
		_last_blip_character = revealed_characters
		typing_blip.emit()

func _begin_conversation() -> void:
	if _conversation_active:
		return
	_conversation_active = true
	conversation_started.emit()

func _end_conversation() -> void:
	if not _conversation_active:
		return
	_conversation_active = false
	conversation_finished.emit()


func _character_of(portrait_id: String) -> String:
	for c in CHARACTERS:
		if portrait_id == c or portrait_id.begins_with(c + "_"):
			return c
	return portrait_id


func _set_portrait(tex: Texture2D, key: String, right_side: bool) -> void:
	if tex == null:
		_portrait_key = ""
		if _portrait.visible:
			if _portrait_tween:
				_portrait_tween.kill()
			_portrait_tween = create_tween()
			_portrait_tween.tween_property(_portrait, "modulate:a", 0.0, 0.15)
			_portrait_tween.finished.connect(_hide_portrait_if_idle)
		return
	if _portrait.visible and key == _portrait_key:
		# Same character as the last line: keep standing there, but swap the
		# texture in case the pose changed (e.g. waving vs. neutral).
		_portrait.texture = tex
		return
	_portrait_key = key
	_portrait.texture = tex
	var x := (size.x - PORTRAIT_MARGIN - PORTRAIT_SIZE.x) if right_side else PORTRAIT_MARGIN
	var y := size.y - PORTRAIT_SIZE.y
	var slide := 70.0 if right_side else -70.0
	_portrait.position = Vector2(x + slide, y)
	_portrait.modulate.a = 0.0
	_portrait.visible = true
	if _portrait_tween:
		_portrait_tween.kill()
	_portrait_tween = create_tween().set_parallel(true)
	_portrait_tween.tween_property(_portrait, "position:x", x, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_portrait_tween.tween_property(_portrait, "modulate:a", 1.0, 0.2)
	# Idle "breathing" so the character isn't a static sticker.
	_portrait.pivot_offset = Vector2(PORTRAIT_SIZE.x * 0.5, PORTRAIT_SIZE.y)
	_portrait.scale = Vector2.ONE
	if _breath_tween:
		_breath_tween.kill()
	_breath_tween = create_tween().set_loops()
	_breath_tween.tween_property(_portrait, "scale:y", 1.015, 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_breath_tween.tween_property(_portrait, "scale:y", 1.0, 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _hide_portrait_if_idle() -> void:
	if _portrait_key == "":
		_portrait.visible = false


func _gui_input(event: InputEvent) -> void:
	# Android turns touches into mouse clicks by default, so this covers taps too.
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		_advance()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_advance()


func _advance() -> void:
	# A tap during the chapter card skips it.
	if _title_tween and _title_tween.is_valid() and _title_tween.is_running():
		_title_tween.kill()
		_end_title()
		return
	if _busy:
		return
	if _typing:
		# First tap: finish the line instantly.
		_type_tween.kill()
		_text.visible_ratio = 1.0
		_finish_typing()
		return
	if _choosing:
		return   # a question: only the answer bubbles move things along
	# Second tap: fade this line out, then tell the caller to move on.
	_busy = true
	var t := create_tween()
	t.tween_property(_group, "modulate:a", 0.0, 0.1)
	await t.finished
	_busy = false
	advanced.emit()


func _finish_typing() -> void:
	_typing = false
	if _choosing:
		_reveal_choices()
		return
	_hint.visible = true
	if _hint_tween:
		_hint_tween.kill()
	_hint.position.y = 0.0
	_hint_tween = create_tween().set_loops()
	_hint_tween.tween_property(_hint, "position:y", 7.0, 0.35)
	_hint_tween.tween_property(_hint, "position:y", 0.0, 0.35)


func _reveal_choices() -> void:
	var i := 0
	for child in _choices.get_children():
		var b := child as Button
		b.pivot_offset = b.size * 0.5
		b.scale = Vector2(0.85, 0.85)
		var delay := 0.09 * i
		var t := create_tween().set_parallel(true)
		t.tween_property(b, "modulate:a", 1.0, 0.15).set_delay(delay)
		t.tween_property(b, "scale", Vector2.ONE, 0.25).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		i += 1
	# Tappable only once they have all started to appear.
	await get_tree().create_timer(0.09 * maxf(0.0, float(i - 1)) + 0.1).timeout
	if not _choosing:
		return
	for child in _choices.get_children():
		(child as Button).disabled = false
	_choices_ready = true


func _on_choice_pressed(index: int) -> void:
	if not _choices_ready:
		return
	_choices_ready = false
	var buttons := _choices.get_children()
	var chosen := buttons[index] as Button
	chosen.add_theme_stylebox_override("disabled", _choice_style(GOLD))   # stays gold while it pops
	chosen.pivot_offset = chosen.size * 0.5
	if chosen.has_meta("tail"):
		var chosen_tail := chosen.get_meta("tail") as Tail
		chosen_tail.fill = GOLD
		chosen_tail.queue_redraw()
	for b in buttons:
		(b as Button).disabled = true
	var t := create_tween().set_parallel(true)
	t.tween_property(chosen, "scale", Vector2(1.06, 1.06), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for b in buttons:
		if b != chosen:
			t.tween_property(b, "modulate:a", 0.0, 0.15)
	t.chain().tween_interval(0.12)
	t.chain().tween_property(_choices, "modulate:a", 0.0, 0.12)
	t.tween_property(_group, "modulate:a", 0.0, 0.12)
	t.finished.connect(_emit_choice.bind(index))


func _emit_choice(index: int) -> void:
	_choosing = false
	choice_made.emit(index)


func _start_bob() -> void:
	# Tiny idle float so the bubble feels alive instead of pinned to the screen.
	if _bob_tween:
		_bob_tween.kill()
	_group.position.y = 0.0
	_bob_tween = create_tween().set_loops()
	_bob_tween.tween_property(_group, "position:y", -4.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_bob_tween.tween_property(_group, "position:y", 0.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _end_title() -> void:
	_title_label.visible = false
	_title_done.emit()


func _finish_close() -> void:
	visible = false
	_portrait.visible = false
	_choices.visible = false

func _exit_tree() -> void:
	_end_conversation()
