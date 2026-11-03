extends Control
## Select a playable campaign day. Story and gameplay run in main.tscn.
const SAVE = preload("res://scripts/campaign_save.gd")
const REPLAY = preload("res://scripts/level_replay.gd")
const CONFIG = preload("res://data/story/summer_campaign.tres")
const FONT = preload("res://assets/fonts/Caveat.ttf")
const THUMBNAILS := ["tonyo_bedroom.png", "day2_box_fall.png", "day3_project_box.png", "day4_alfa_save_corner.png", "day5_tonyo_wakes.png", "day6_fiesta_fireworks.png", "day7_tonyo_miniature.png"]
var saved: Dictionary
var progress: StoryProgression
var debug_preview := false
var canvas: Control
var stage: Control
var board_scroll: ScrollContainer
var portrait_layout := false
var day := 0
var audio: KwentaAudio

func _ready() -> void:
	name = "CampaignBoard"
	z_index = 100
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if get_tree().has_meta(REPLAY.RETURN_META):
		var returned: Dictionary = get_tree().get_meta(REPLAY.RETURN_META)
		debug_preview = bool(returned.get("debug_access", false)) and OS.is_debug_build()
		get_tree().remove_meta(REPLAY.RETURN_META)
	saved = SAVE.load_progress()
	progress = StoryProgression.new(CONFIG)
	progress.choices = saved.get("choices", {}).duplicate(true)
	audio = preload("res://scripts/kwenta_audio.gd").new()
	audio.register_default_music()
	add_child(audio)
	audio.set_music("main_menu")
	var background := ColorRect.new()
	background.color = Color("302119")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	canvas = Control.new()
	add_child(canvas)
	stage = Control.new()
	canvas.add_child(stage)
	resized.connect(_layout)
	_layout()

func _layout() -> void:
	if size.x <= 0 or size.y <= 0: return
	portrait_layout = size.x < size.y
	var factor := size.x / 1080.0 if portrait_layout else size.y / 1080.0
	canvas.size = size / factor
	canvas.scale = Vector2.ONE * factor
	stage.size = canvas.size
	if day > 0: _show_chapter(day)
	else: _show_board()

func _clear() -> void:
	for child in stage.get_children():
		stage.remove_child(child)
		child.queue_free()

func _text(text: String, at: Vector2, bounds: Vector2, font_size: int = 42) -> Label:
	var label := Label.new()
	label.text = text
	label.position = at
	label.size = bounds
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
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

func _picture(path: String, at: Vector2, bounds: Vector2) -> void:
	var picture := TextureRect.new()
	picture.position = at
	picture.size = bounds
	picture.texture = load(path) as Texture2D
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(picture)

func is_unlocked(chapter: int) -> bool:
	return chapter >= 1 and chapter <= 7 and (bool(saved.get("completed", false)) or (debug_preview and OS.is_debug_build()))

func _show_board() -> void:
	day = 0
	_clear()
	var width := canvas.size.x
	var height := canvas.size.y
	_text("Campaign Board", Vector2(60, 30), Vector2(width - 120, 100), 76)
	_text("Choose a day to play again", Vector2(65, 140), Vector2(width - 130, 60), 40)
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
	content.custom_minimum_size = Vector2(width - 120, ceili(7.0 / columns) * (card_height + 25))
	board_scroll.add_child(content)
	var screen_stage := stage
	stage = content
	for offset in range(7):
		var chapter := offset + 1
		var at := Vector2(10 + offset % columns * (card_width + 25), 10 + floori(float(offset) / columns) * (card_height + 25))
		var card := _button("", at, Vector2(card_width, card_height), func(): _show_chapter(chapter))
		card.name = "Day%dButton" % chapter
		card.disabled = not is_unlocked(chapter)
		for state in ["normal", "hover", "pressed", "disabled", "focus"]:
			var paper := StyleBoxFlat.new()
			paper.bg_color = Color("fff0cf") if not card.disabled else Color("89755e")
			if state in ["hover", "focus"]: paper.bg_color = Color("ffdc98")
			paper.set_corner_radius_all(8)
			card.add_theme_stylebox_override(state, paper)
		if not card.disabled: _picture("res://assets/story/" + THUMBNAILS[offset], at + Vector2(16, 15), Vector2(card_width - 32, card_height - 115))
		var caption := _text("Day %d · %s" % [chapter, progress.get_day_title(chapter)] if not card.disabled else "Day %d · Locked" % chapter, at + Vector2(15, card_height - 90), Vector2(card_width - 30, 85), 36 if portrait_layout else 32)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.add_theme_color_override("font_color", Color("41271d"))
	stage = screen_stage
	_button("← Debug menu" if debug_preview and get_parent() is CanvasLayer else "Main menu", Vector2(60, height - 100), Vector2(360, 80), _close)

func _show_chapter(chapter: int) -> void:
	if not is_unlocked(chapter): return
	day = chapter
	_clear()
	var width := canvas.size.x
	var height := canvas.size.y
	_text("Day %d · %s" % [day, progress.get_day_title(day)], Vector2(60, 40), Vector2(width - 120, 130), 65)
	var art_bounds := Vector2(width - 120, clampf(height - 850, 180, 600)) if portrait_layout else Vector2(width * 0.54 - 80, height - 330)
	_picture("res://assets/story/" + THUMBNAILS[day - 1], Vector2(60, 200), art_bounds)
	var at := Vector2(60, 250 + art_bounds.y) if portrait_layout else Vector2(width * 0.57, 300)
	var body_width := width - 120 if portrait_layout else width * 0.43 - 60
	_text("Play the full day: serve customers, complete its goal, and experience its story.\n\nYour main campaign progress stays safe.", at, Vector2(body_width, 240), 42)
	var play := _button("PLAY DAY %d" % day, at + Vector2(0, 290), Vector2(body_width, 100), _play_day)
	play.name = "PlayDayButton"
	play.grab_focus()
	_button("← Campaign board", Vector2(60, height - 100), Vector2(400, 80), _show_board)

func _play_day() -> void:
	REPLAY.launch(get_tree(), day, debug_preview)

func _close() -> void:
	if get_tree().current_scene == self:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	else: queue_free()
