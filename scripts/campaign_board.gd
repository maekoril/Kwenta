extends Control
## Read-only chapter replays. Never instantiates gameplay or writes a save.
const SAVE = preload("res://scripts/campaign_save.gd")
const CONFIG = preload("res://data/story/summer_campaign.tres")
const FONT = preload("res://assets/fonts/Caveat.ttf")
const ART = preload("res://scripts/counter_art.gd")
const ATLAS = preload("res://assets/characters/shared/customer_portraits_v2.png")
const PICTURES := {
	"box_fall": "day2_box_fall.png", "day3_project": "day3_project_box.png",
	"day4_alfa_save": "day4_alfa_save_corner.png", "day5_wakes": "day5_tonyo_wakes.png",
	"day5_phone": "day5_tonyo_phone_v2.png", "day6_fireworks": "day6_fiesta_fireworks.png",
	"day7_walk": "day7_classroom_turn.png", "day7_classmates": "day7_classmates_listening.png",
	"day7_tonyo_face": "day7_tonyo_presenting.png", "day7_project": "day7_tonyo_miniature.png"
}
const PROPS := {
	"berting_counter_closeup": "berting_counter_50.png", "umbrella_handoff": "day4_tonyo_lends_umbrella_stocked_tonyo.png",
	"fiesta_powerline": "day6_fiesta_powerline.png", "rosa_payment": "day5_rosa_payment.png",
	"paolo_coins": "day3_paolo_coins_casual.png", "lina_walking_away": "day4_lina_alfa_corner.png",
	"friends_shelter": "day4_friends_shelter.png", "alfa_save_corner": "day4_alfa_save_corner.png"
}
const THUMBNAILS := ["tonyo_bedroom.png", "tonyo_bedroom.png", "day2_box_fall.png", "day3_project_box.png", "day4_alfa_save_corner.png", "day5_tonyo_wakes.png", "day6_fiesta_fireworks.png", "day7_tonyo_miniature.png"]
var progress: StoryProgression
var saved: Dictionary
var canvas: Control
var stage: Control
var day := 0
var beats: Array[Dictionary] = []
var images: Array[String] = []
var index := 0
var image: TextureRect
var portrait: TextureRect
var dialogue: Label
var counter: Label
var previous: Button
var next: Button
var fade: Tween
var audio: KwentaAudio
var debug_preview := false
var view := "board"
var portrait_layout := false
var board_scroll: ScrollContainer
var dialogue_scroll: ScrollContainer
var time_card: ColorRect
var time_title: Label
var time_animation: Tween
var replay_background: ColorRect

func _ready() -> void:
	name = "CampaignBoard"
	z_index = 100
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	saved = SAVE.load_progress()
	progress = StoryProgression.new(CONFIG)
	progress.choices = saved.get("choices", {}).duplicate(true)
	audio = preload("res://scripts/kwenta_audio.gd").new()
	audio.register_default_music()
	add_child(audio)
	var dim := ColorRect.new()
	dim.color = Color("302119")
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	canvas = Control.new()
	canvas.size = Vector2(1920, 1080)
	add_child(canvas)
	stage = Control.new()
	stage.size = canvas.size
	canvas.add_child(stage)
	resized.connect(_layout)
	_layout()
	_show_board()

func _layout() -> void:
	if size.x <= 0 or size.y <= 0:
		return
	portrait_layout = size.x < size.y
	var factor := size.x / 1080.0 if portrait_layout else size.y / 1080.0
	canvas.size = size / factor
	canvas.scale = Vector2.ONE * factor
	canvas.position = Vector2.ZERO
	stage.size = canvas.size
	if view == "replay" and not beats.is_empty():
		_build_replay()
	elif view == "chapter":
		_show_chapter(day)
	else:
		_show_board()

func _clear() -> void:
	if time_animation != null:
		time_animation.kill()
	if fade != null:
		fade.kill()
	for child in stage.get_children():
		stage.remove_child(child)
		child.queue_free()

func _text(text: String, at: Vector2, bounds: Vector2, font_size: int = 42) -> Label:
	var label := Label.new()
	label.text = text
	label.position = at
	label.size = bounds
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("ffedc8"))
	stage.add_child(label)
	return label

func _button(text: String, at: Vector2, bounds: Vector2, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.position = at
	button.size = bounds
	button.add_theme_font_override("font", FONT)
	button.add_theme_font_size_override("font_size", 36)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(action)
	stage.add_child(button)
	return button

func _picture(path: String, at: Vector2, bounds: Vector2) -> TextureRect:
	var picture := TextureRect.new()
	picture.position = at
	picture.size = bounds
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not path.is_empty():
		picture.texture = load(path) as Texture2D
	stage.add_child(picture)
	return picture

func is_unlocked(chapter: int) -> bool:
	if debug_preview and OS.is_debug_build():
		return true
	if chapter == 0:
		return true
	return bool(saved.get("completed", false)) or chapter < int(saved.get("campaign", {}).get("day", 1)) or not str(progress.choices.get("diary_day_%d" % chapter, "")).is_empty()

func _show_board() -> void:
	view = "board"
	_clear()
	audio.set_music("main_menu")
	var width := canvas.size.x
	var height := canvas.size.y
	_text("Campaign Board", Vector2(60, 30), Vector2(width - 120, 100), 76)
	_text("Debug preview · all days" if debug_preview else "Revisit Tonyo's story", Vector2(65, 140), Vector2(width - 130, 60), 36)
	board_scroll = ScrollContainer.new()
	board_scroll.name = "ChapterScroll"
	board_scroll.position = Vector2(50, 225)
	board_scroll.size = Vector2(width - 100, height - 360)
	board_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	stage.add_child(board_scroll)
	var content := Control.new()
	var columns := 2 if portrait_layout else 4
	var card_width := (width - 140 - (columns - 1) * 25) / columns
	var card_height := 350.0 if portrait_layout else 310.0
	content.custom_minimum_size = Vector2(width - 120, ceili(8.0 / columns) * (card_height + 25))
	board_scroll.add_child(content)
	var screen_stage := stage
	stage = content
	for chapter in range(8):
		var unlocked := is_unlocked(chapter)
		var at := Vector2(10 + chapter % columns * (card_width + 25), 10 + floori(float(chapter) / columns) * (card_height + 25))
		var title := "Prologue" if chapter == 0 else "Day %d · %s" % [chapter, progress.get_day_title(chapter)]
		var card := _button("", at, Vector2(card_width, card_height), func(): _show_chapter(chapter))
		card.disabled = not unlocked
		for state in ["normal", "hover", "pressed", "disabled", "focus"]:
			var paper := StyleBoxFlat.new()
			paper.bg_color = Color("fff0cf") if unlocked else Color("89755e")
			if state in ["hover", "focus"]:
				paper.bg_color = Color("ffdc98")
			paper.set_corner_radius_all(8)
			paper.shadow_size = 8
			paper.shadow_color = Color(0, 0, 0, 0.25)
			card.add_theme_stylebox_override(state, paper)
		if unlocked:
			_picture("res://assets/story/" + THUMBNAILS[chapter], at + Vector2(16, 15), Vector2(card_width - 32, card_height - 115))
		var caption := _text(title if unlocked else "Day %d\nNot yet completed", at + Vector2(15, card_height - 90 if unlocked else 100), Vector2(card_width - 30, 85), 36 if portrait_layout else 32)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		caption.add_theme_color_override("font_color", Color("41271d"))
	stage = screen_stage
	_button("← Debug menu" if debug_preview else "Main menu", Vector2(60, height - 100), Vector2(360, 80), queue_free)

func _show_chapter(chapter: int) -> void:
	if not is_unlocked(chapter):
		return
	day = chapter
	if day == 0:
		_start_replay(progress.get_prologue_beats())
		return
	view = "chapter"
	_clear()
	var width := canvas.size.x
	var height := canvas.size.y
	_text("Day %d · %s" % [day, progress.get_day_title(day)], Vector2(60, 40), Vector2(width - 120, 130), 65)
	var art_bounds := Vector2(width - 120, clampf(height - 1000, 140, 500)) if portrait_layout else Vector2(width * 0.50 - 80, height - 330)
	_picture("res://assets/story/" + THUMBNAILS[day], Vector2(60, 200), art_bounds)
	var section_at := Vector2(60, 230 + art_bounds.y) if portrait_layout else Vector2(width * 0.54, 240)
	var section_width := width - 120 if portrait_layout else width * 0.46 - 60
	var sections := [progress.get_day_intro_beats(day), progress.get_day_outro_beats(day), _saved_responses(), progress.get_day_callback_beats(day)]
	for section in range(4):
		var section_beats: Array[Dictionary] = sections[section]
		var button := _button(["Opening scene", "Closing scene", "Your choices", "Aftermath / ending"][section], section_at + Vector2(0, section * 125), Vector2(section_width, 100), func(): _start_replay(section_beats))
		button.disabled = section_beats.is_empty()
	_text("Replays follow your saved choices.", section_at + Vector2(0, 515), Vector2(section_width, 100), 36)
	_button("← Campaign board", Vector2(60, height - 100), Vector2(400, 80), _show_board)

func _saved_responses() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var choices := progress.get_day_intro_choices(day)
	choices.append_array(progress.get_day_choices(day))
	for choice in choices:
		for option in choice.get("options", []):
			if str(option.get("id", "")) != progress.get_choice(str(choice.get("id", ""))):
				continue
			var response: Variant = option.get("response", "")
			if response is Array:
				result.append_array(progress.filter_story_beats(response))
			elif not str(response).is_empty():
				result.append({"speaker": option.get("response_speaker", "Tonyo"), "portrait": option.get("response_portrait", "tonyo"), "text": str(response)})
	return result

func _start_replay(source: Array[Dictionary]) -> void:
	audio.set_music("rain" if day == 4 else ("intense" if day == 6 else "normal"))
	beats = source.duplicate(true)
	images.clear()
	var current: String = "res://assets/story/" + THUMBNAILS[day]
	for beat in beats:
		var cue := str(beat.get("cutscene", ""))
		if cue == "day7_time_card":
			current = ""
		if PICTURES.has(cue):
			current = "res://assets/story/" + str(PICTURES[cue])
		var prop := str(beat.get("show_prop", ""))
		if PROPS.has(prop):
			current = "res://assets/story/" + str(PROPS[prop])
		if prop.begins_with("hide_"):
			current = "res://assets/store/backgrounds/bg_empty.png"
		if cue in ["end", "day5_to_store"]:
			current = "res://assets/store/backgrounds/bg_empty.png"
		images.append(current)
	index = 0
	_build_replay()

func _build_replay() -> void:
	view = "replay"
	_clear()
	var width := canvas.size.x
	var height := canvas.size.y
	var picture_height := height * 0.49 if portrait_layout else height - 390
	replay_background = ColorRect.new()
	replay_background.size = canvas.size
	replay_background.color = Color.BLACK
	replay_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(replay_background)
	image = _picture("", Vector2(30, 20), Vector2(width - 60, picture_height - 20))
	portrait = _picture("", Vector2(40, picture_height + 30), Vector2(160, 190))
	dialogue_scroll = ScrollContainer.new()
	dialogue_scroll.name = "DialogueScroll"
	dialogue_scroll.position = Vector2(225, picture_height + 25)
	dialogue_scroll.size = Vector2(width - 275, height - picture_height - 165)
	dialogue_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	stage.add_child(dialogue_scroll)
	dialogue = _text("", Vector2.ZERO, Vector2(width - 300, 0), 44 if portrait_layout else 40)
	stage.remove_child(dialogue)
	dialogue.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialogue_scroll.add_child(dialogue)
	counter = _text("", Vector2(width * 0.5 - 80, height - 150), Vector2(180, 50), 30)
	var button_width := (width - 140) / 3
	_button("← Board", Vector2(40, height - 100), Vector2(button_width, 80), _show_board)
	previous = _button("Previous", Vector2(70 + button_width, height - 100), Vector2(button_width, 80), func(): index = maxi(0, index - 1); _refresh_beat())
	next = _button("Next →", Vector2(100 + button_width * 2, height - 100), Vector2(button_width, 80), _advance)
	time_card = ColorRect.new()
	time_card.name = "ReplayTimeCard"
	time_card.size = canvas.size
	time_card.color = Color.BLACK
	time_card.z_index = 20
	stage.add_child(time_card)
	time_title = Label.new()
	time_title.size = canvas.size
	time_title.text = "Kinabukasan..."
	time_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	time_title.add_theme_font_size_override("font_size", 48)
	time_title.add_theme_color_override("font_color", Color.WHITE)
	time_card.add_child(time_title)
	next.grab_focus()
	_refresh_beat()

func _advance() -> void:
	if is_instance_valid(time_card) and time_card.visible:
		return
	if index + 1 >= beats.size():
		_show_chapter(day) if day > 0 else _show_board()
	else:
		index += 1
		_refresh_beat()

func _refresh_beat() -> void:
	if beats.is_empty():
		_show_board()
		return
	var beat := beats[index]
	if time_animation != null:
		time_animation.kill()
	time_card.hide()
	replay_background.visible = images[index].is_empty()
	dialogue_scroll.scroll_vertical = 0
	image.texture = load(images[index]) as Texture2D if not images[index].is_empty() else null
	var portrait_id := str(beat.get("portrait", ""))
	portrait.texture = ART.customer_portrait(portrait_id, ATLAS) if not portrait_id.is_empty() else null
	dialogue.text = "%s\n%s" % [str(beat.get("speaker", "Narrator")), str(beat.get("text", ""))]
	if dialogue.text.strip_edges() == "Narrator":
		dialogue.text = "Makalipas ang ilang araw…" if beat.get("cutscene", "") == "day7_time_card" else "…"
	counter.text = "%d / %d" % [index + 1, beats.size()]
	previous.disabled = index == 0
	next.text = "Finish replay" if index == beats.size() - 1 else "Next →"
	if fade != null:
		fade.kill()
	image.modulate.a = 0.35
	fade = create_tween()
	fade.tween_property(image, "modulate:a", 1.0, 0.25)
	if str(beat.get("cutscene", "")) == "day7_time_card":
		if index > 0 and not images[index - 1].is_empty():
			image.texture = load(images[index - 1]) as Texture2D
			image.modulate.a = 1.0
		time_card.show()
		time_card.modulate.a = 0.0
		time_title.modulate.a = 0.0
		time_animation = create_tween()
		time_animation.tween_property(time_card, "modulate:a", 1.0, 0.6)
		time_animation.tween_property(time_title, "modulate:a", 1.0, 0.8)
		time_animation.tween_interval(1.4)
		time_animation.tween_property(time_title, "modulate:a", 0.0, 0.6)
		time_animation.tween_callback(func():
			time_card.hide()
			_advance()
		)
