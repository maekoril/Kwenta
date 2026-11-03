extends Control
## A self-contained curtain call, shared by the ending and main-menu preview.
signal closed
signal campaign_board_requested

const DESIGN := Vector2(1920, 1080)
const FONT = preload("res://assets/fonts/Caveat.ttf")
const CAST := ["tonyo/tonyo_full_front.png", "jun_jun/jun_jun_full_front_v2.png", "bogs/bogs_full_front.png", "aling_cora/aling_cora_full_front.png", "mikay/mikay_full_front.png"]
var canvas: Control
var stage: Control
var page := 0
var entrance: Tween
var idle: Tween
var content: Dictionary
var campaign_board_available := true

func _ready() -> void:
	name = "Credits"
	z_index = 100
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content = JSON.parse_string(FileAccess.get_file_as_string("res://data/credits.json"))
	var backdrop := ColorRect.new()
	backdrop.color = Color("281d22")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	canvas = Control.new()
	canvas.size = DESIGN
	add_child(canvas)
	var background := TextureRect.new()
	background.texture = preload("res://assets/store/backgrounds/bg_empty_golden_hour.png")
	background.size = DESIGN
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.modulate = Color(0.48, 0.40, 0.35)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(background)
	stage = Control.new()
	stage.size = DESIGN
	canvas.add_child(stage)
	resized.connect(_layout)
	_layout()
	_show_page()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.6)

func _layout() -> void:
	var factor := minf(size.x / DESIGN.x, size.y / DESIGN.y)
	canvas.scale = Vector2.ONE * factor
	canvas.position = (size - DESIGN * factor) * 0.5

func _label(text: String, at: Vector2, dimensions: Vector2, font_size: int = 48) -> Label:
	var label := Label.new()
	label.text = text
	label.position = at
	label.size = dimensions
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("41271d"))
	stage.add_child(label)
	return label

func _button(text: String, at: Vector2, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.position = at
	button.size = Vector2(310, 70)
	button.add_theme_font_override("font", FONT)
	button.add_theme_font_size_override("font_size", 38)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(action)
	stage.add_child(button)
	return button

func _show_page() -> void:
	if entrance != null:
		entrance.kill()
	if idle != null:
		idle.kill()
	for child in stage.get_children():
		stage.remove_child(child)
		child.queue_free()
	var paper := Panel.new()
	paper.position = Vector2(380, 110)
	paper.size = Vector2(1160, 590)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("fff0cf")
	style.set_corner_radius_all(20)
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_size = 18
	paper.add_theme_stylebox_override("panel", style)
	stage.add_child(paper)
	var titles := ["Created by", "Music & Sound", "Salamat sa paglalaro!"]
	_label(titles[page], Vector2(420, 130), Vector2(1080, 115), 76)
	entrance = create_tween().set_parallel(true)
	idle = create_tween().set_loops()
	var actors: Array[Control] = []
	var count := 5 if page == 2 else (3 if page == 0 else 2)
	for index in range(count):
		var cast_index := index if page != 1 else index + 3
		var actor := TextureRect.new()
		actor.texture = load("res://assets/characters/" + CAST[cast_index]) as Texture2D
		actor.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		actor.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		actor.size = Vector2(310, 430)
		var target := Vector2(280 + index * 260 if page == 2 else 400 + index * 410, 570)
		actor.position = target + Vector2(-450 if index % 2 == 0 else 450, 400)
		actor.pivot_offset = actor.size * Vector2(0.5, 0.9)
		actor.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stage.add_child(actor)
		actors.append(actor)
		entrance.tween_property(actor, "position", target, 0.8).set_delay(index * 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		entrance.tween_property(actor, "rotation", -0.035 if index % 2 == 0 else 0.035, 0.4).set_delay(index * 0.22 + 0.8)
	if page < 2:
		var entries: Array = content["team" if page == 0 else "audio"]
		for index in range(entries.size()):
			var entry := _label(str(entries[index]), Vector2(430, 265 + index * 82), Vector2(1060, 75), 52 if page == 0 else 32)
			entry.modulate.a = 0.0
			entrance.tween_property(entry, "modulate:a", 1.0, 0.4).set_delay(0.4 + index * 0.25)
	else:
		_label("Isang linggo. Isang tindahan. Maraming kuwento.\nThank you for being part of Tonyo's story.", Vector2(440, 280), Vector2(1040, 220), 48)
	for actor in actors:
		idle.parallel().tween_property(actor, "rotation", 0.025, 1.1).set_delay(1.8).set_trans(Tween.TRANS_SINE)
	idle.chain()
	for actor in actors:
		idle.parallel().tween_property(actor, "rotation", -0.025, 1.1).set_trans(Tween.TRANS_SINE)
	_label("KWENTA  /  %d OF 3" % (page + 1), Vector2(700, 25), Vector2(520, 60), 30).add_theme_color_override("font_color", Color("ffe4ad"))
	var exit_button := _button("×", Vector2(1640, 30), _close)
	exit_button.size = Vector2(80, 70)
	exit_button.tooltip_text = "Main menu"
	if page < 2:
		_button("Next →", Vector2(1200, 975), func(): page += 1; _show_page()).grab_focus()
		_board_button(Vector2(410, 975))
	else:
		_button("Replay credits", Vector2(410, 975), func(): page = 0; _show_page())
		_board_button(Vector2(1200, 975)).grab_focus()

func _board_button(at: Vector2) -> Button:
	var button := _button("View Campaign Board", at, func():
		campaign_board_requested.emit()
		queue_free()
	)
	button.name = "ViewCampaignBoardButton"
	button.add_theme_font_size_override("font_size", 30)
	button.disabled = not campaign_board_available
	if button.disabled:
		button.tooltip_text = "Finish the campaign to unlock the board."
	return button

func _close() -> void:
	closed.emit()
	queue_free()
