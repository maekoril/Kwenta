extends Control

const UNEARNED = preload("res://shaders/unearned_medal.gdshader")
const GOAL = preload("res://scripts/daily_goal.gd")
const HANDWRITING = preload("res://assets/fonts/Caveat.ttf")
const BOOK_SIZE := Vector2(1400, 850)
const MEDAL_NAMES := ["Unang Benta", "Tamang Sukli", "Maayos na Order", "Tag-ulan", "Suki", "Fiesta", "Mga Suki"]
var story
var days: Array[int] = []
var page_index := 0
var section := 0
var medal_day := 1
var heading: Label
var entry_label: Label
var choice_label: Label
var goal_label: Label
var medal: TextureRect
var previous_button: Button
var next_button: Button
var book: Control
var story_page: Control
var collection_page: Control
var section_buttons: Array[Button] = []
var day_buttons: Array[Button] = []
var collection_buttons: Array[Button] = []
var keepsake: Label
var page_number: Label
var medal_title: Label
var collection_count: Label
var gallery: Control
var page_turn: Control
var page_turn_tween: Tween

func _ready() -> void:
	name = "DiaryReader"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.06, 0.04, 0.025, 0.8)
	add_child(dim)
	book = Control.new()
	book.size = BOOK_SIZE
	book.draw.connect(_draw_book)
	add_child(book)
	for i in range(3):
		var button := _button(["MGA KWENTO", "MGA MEDALYA", "MGA LARAWAN"][i], Vector2(60 + i * 265, 8), Vector2(250, 62))
		button.pressed.connect(func(): _select_section(i))
		section_buttons.append(button)
	heading = _label(book, "KUWADERNO NI TONYO", Vector2(72, 95), Vector2(1150, 42), 30)
	heading.add_theme_color_override("font_color", KwentaStyle.PAPER)
	var close_button := _button("ISARA ×", Vector2(1175, 85), Vector2(155, 56))
	close_button.pressed.connect(close)
	for i in range(7):
		var tab := _button("%d" % (i + 1), Vector2(1340, 175 + i * 79), Vector2(55, 65))
		tab.tooltip_text = "Araw %d" % (i + 1)
		tab.pressed.connect(func(): _select_day(i + 1))
		day_buttons.append(tab)
	story_page = Control.new()
	book.add_child(story_page)
	_label(story_page, "MGA ARAW SA TINDAHAN", Vector2(100, 171), Vector2(510, 34), 22)
	entry_label = _label(story_page, "", Vector2(100, 232), Vector2(510, 310), 38, true)
	keepsake = _label(story_page, "", Vector2(132, 592), Vector2(440, 85), 29, true)
	keepsake.rotation = -0.035
	_label(story_page, "ANG MGA PINILI KO", Vector2(768, 171), Vector2(490, 34), 22)
	choice_label = _label(story_page, "", Vector2(768, 226), Vector2(490, 125), 31, true)
	collection_page = Control.new()
	book.add_child(collection_page)
	_label(collection_page, "BAWAT TAGUMPAY, MAY KWENTO", Vector2(768, 171), Vector2(490, 34), 22)
	_label(collection_page, "Piliin ang isang medalya o gamitin ang day tabs para balikan ang bawat araw.", Vector2(768, 226), Vector2(490, 125), 31, true)
	_label(collection_page, "MUNTING TAGUMPAY", Vector2(100, 171), Vector2(510, 34), 22)
	collection_count = _label(collection_page, "", Vector2(100, 215), Vector2(510, 40), 30, true)
	for i in range(7):
		var button := Button.new()
		button.position = Vector2(100 + (i % 3) * 173, 280 + (i / 3) * 141)
		button.size = Vector2(155, 128)
		button.text = "ARAW %d" % (i + 1)
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		button.add_theme_constant_override("icon_max_width", 76)
		KwentaStyle.style_button(button, KwentaStyle.PAPER_DARK, 18)
		button.pressed.connect(func(): _select_day(i + 1))
		collection_page.add_child(button)
		collection_buttons.append(button)
	medal_title = _label(book, "", Vector2(768, 370), Vector2(490, 44), 33, true)
	medal = TextureRect.new()
	medal.position = Vector2(925, 430)
	medal.size = Vector2(170, 170)
	medal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	medal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	book.add_child(medal)
	goal_label = _label(book, "", Vector2(768, 620), Vector2(490, 100), 23)
	gallery = preload("res://scripts/notebook_gallery.gd").new()
	book.add_child(gallery)
	gallery.hide()
	previous_button = _button("< NAKARAAN", Vector2(85, 763), Vector2(240, 60))
	previous_button.pressed.connect(func(): _flip(-1))
	next_button = _button("SUSUNOD >", Vector2(1085, 763), Vector2(240, 60))
	next_button.pressed.connect(func(): _flip(1))
	page_number = _label(book, "", Vector2(490, 775), Vector2(420, 40), 22)
	page_number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page_turn = preload("res://scripts/notebook_page_turn.gd").new()
	page_turn.name = "PageTurnAnimation"
	page_turn.z_index = 20
	book.add_child(page_turn)
	resized.connect(_layout)
	_layout()

func _label(parent: Control, text: String, at: Vector2, bounds: Vector2, font_size: int, handwritten := false) -> Label:
	var label := KwentaStyle.make_label(text, font_size, KwentaStyle.INK)
	label.position = at
	label.size = bounds
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if handwritten:
		label.add_theme_font_override("font", HANDWRITING)
	parent.add_child(label)
	return label

func _button(text: String, at: Vector2, bounds: Vector2) -> Button:
	var button := Button.new()
	button.text = text
	button.position = at
	button.size = bounds
	KwentaStyle.style_button(button, KwentaStyle.PAPER_DARK, 22)
	book.add_child(button)
	return button

func _layout() -> void:
	var fit := minf((size.x - 40) / BOOK_SIZE.x, (size.y - 40) / BOOK_SIZE.y)
	book.scale = Vector2.ONE * maxf(0.1, fit)
	book.position = (size - BOOK_SIZE * book.scale) * 0.5

func _draw_book() -> void:
	book.draw_style_box(KwentaStyle.box(Color("795035"), Color("38271c"), 0, 0, 15, 5, 10), Rect2(35, 57, 1310, 785))
	for x in [65, 711]:
		# Layered page edges and a warm inset make the spread feel like paper.
		book.draw_rect(Rect2(x + 5, 149, 615, 595), Color("8a6542", 0.16))
		book.draw_style_box(KwentaStyle.box(Color("fff1d3"), Color("c5a681"), 0, 0, 3, 2, 0), Rect2(x, 145, 615, 595))
		for y in range(218, 727, 46):
			book.draw_line(Vector2(x + 18, y), Vector2(x + 596, y), Color("a3b8b4", 0.4), 1)
		book.draw_line(Vector2(x + 32, 160), Vector2(x + 32, 722), Color("ce8881", 0.5), 2)
		book.draw_line(Vector2(x + 40, 207), Vector2(x + 580, 207), Color("b59266", 0.55), 2)
		book.draw_circle(Vector2(x + 581, 180), 4, Color("b58a52", 0.65))
	book.draw_rect(Rect2(680, 145, 31, 595), Color("b89973"))
	book.draw_rect(Rect2(669, 151, 10, 583), Color("8c6d4d", 0.14))
	book.draw_rect(Rect2(711, 151, 10, 583), Color("8c6d4d", 0.14))
	for y in range(190, 720, 75):
		book.draw_circle(Vector2(677, y), 6, Color("5c422d"))
		book.draw_circle(Vector2(714, y), 6, Color("5c422d"))
		book.draw_arc(Vector2(695, y), 19, PI, TAU, 20, Color("594431"), 5, true)
	if section == 0:
		book.draw_style_box(KwentaStyle.box(Color("f0dbaa"), Color("d1b688"), 0, 0, 2, 1, 3), Rect2(116, 566, 480, 133))
		book.draw_rect(Rect2(273, 554, 140, 26), Color("d4b985", 0.7))

func open(progress) -> void:
	_stop_page_turn()
	gallery.viewer.hide()
	story = progress
	days.clear()
	if story != null:
		for day in range(1, 8):
			if not str(story.choices.get("diary_day_%d" % day, "")).is_empty():
				days.append(day)
	page_index = maxi(days.size() - 1, 0)
	medal_day = days[page_index] if not days.is_empty() else 1
	section = 0
	_refresh()
	visible = true

func close() -> void:
	_stop_page_turn()
	gallery.viewer.hide()
	visible = false

func go_back() -> void:
	if gallery.viewer.visible:
		gallery.viewer.hide()
	else:
		close()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		go_back()
	elif event.is_action_pressed("ui_left"):
		_flip(-1)
	elif event.is_action_pressed("ui_right"):
		_flip(1)
	else:
		return
	get_viewport().set_input_as_handled()

func _select_section(value: int) -> void:
	_stop_page_turn()
	if value != 0 and section == 0 and not days.is_empty():
		medal_day = days[page_index]
	elif value == 0 and days.has(medal_day):
		page_index = days.find(medal_day)
	section = value
	gallery.viewer.hide()
	_refresh()

func _select_day(day: int) -> void:
	_stop_page_turn()
	if section == 0:
		if not days.has(day):
			return
		page_index = days.find(day)
	medal_day = day
	_refresh()

func _flip(direction: int) -> void:
	var old_day := (page_index if section == 0 else medal_day)
	if section == 0:
		page_index = clampi(page_index + direction, 0, maxi(days.size() - 1, 0))
	else:
		medal_day = clampi(medal_day + direction, 1, 7)
	var new_day := (page_index if section == 0 else medal_day)
	if old_day == new_day: return
	_refresh()
	if section == 0:
		_animate_page_turn(direction)
	else:
		_stop_page_turn()

func _stop_page_turn() -> void:
	if page_turn_tween != null and page_turn_tween.is_valid(): page_turn_tween.kill()
	if is_instance_valid(page_turn): page_turn.hide()

func _animate_page_turn(direction: int) -> void:
	if not is_instance_valid(page_turn): return
	_stop_page_turn()
	page_turn.direction = direction
	page_turn.progress = 0.0
	page_turn.show()
	page_turn_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	page_turn_tween.tween_property(page_turn, "progress", 1.0, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	page_turn_tween.tween_callback(page_turn.hide)

func _result(day: int) -> String:
	return str(story.choices.get("diary_goal_day_%d" % day, "")) if story != null else ""

func _refresh() -> void:
	var day := (days[page_index] if not days.is_empty() else 1) if section == 0 else medal_day
	story_page.visible = section == 0
	collection_page.visible = section == 1
	gallery.visible = section == 2
	medal.visible = section != 2
	medal_title.visible = section != 2
	goal_label.visible = section != 2
	if section == 2:
		gallery.show_day(story, day)
	heading.text = "KUWADERNO NI TONYO  /  %s  /  DAY %d" % [["MGA KWENTO", "MGA MEDALYA", "MGA LARAWAN"][section], day]
	previous_button.disabled = (days.is_empty() or page_index == 0) if section == 0 else day == 1
	next_button.disabled = (days.is_empty() or page_index >= days.size() - 1) if section == 0 else day == 7
	for i in range(3):
		KwentaStyle.style_button(section_buttons[i], KwentaStyle.GOLD if section == i else KwentaStyle.PAPER_DARK, 22)
	var earned := 0
	for i in range(7):
		day_buttons[i].disabled = section == 0 and not days.has(i + 1)
		KwentaStyle.style_button(day_buttons[i], KwentaStyle.GOLD if day == i + 1 else KwentaStyle.PAPER_DARK, 22)
		var result := _result(i + 1)
		var icon: Texture2D = load("res://assets/sprites/ui/daily_medals/day_%d.png" % (i + 1)) if not result.is_empty() else null
		collection_buttons[i].icon = icon
		collection_buttons[i].text = "???" if result.is_empty() else "ARAW %d%s" % [i + 1, " · ✓" if result == "earned" else "\nHINDI NAKAMIT"]
		KwentaStyle.style_button(collection_buttons[i], KwentaStyle.GOLD if day == i + 1 else Color("efe0be"), 18)
		collection_buttons[i].material = null
		if result == "missed":
			var grayscale := ShaderMaterial.new()
			grayscale.shader = UNEARNED
			collection_buttons[i].material = grayscale
		collection_buttons[i].tooltip_text = "%s · %s" % [MEDAL_NAMES[i] if not result.is_empty() else "???", "Nakamit" if result == "earned" else ("Hindi nakamit" if result == "missed" else "???")]
		if result == "earned": earned += 1
	collection_count.text = "%d sa 7 medalya ang nakamit." % earned
	entry_label.text = str(story.choices.get("diary_day_%d" % day, "")) if story != null else ""
	if days.is_empty(): entry_label.text = "Wala pang naisusulat si Tonyo. Pagkatapos ng unang araw, dito magsisimula ang kanyang kwento."
	choice_label.text = _choice_text(day) if not days.is_empty() else "Bawat araw, may kwentong maiuuwi."
	keepsake.text = {1: "Unang pahina. Unang araw sa tindahan.", 2: "Paalala: bayad − bili = sukli", 3: "Tala: " + _choice_text(3).get_slice("\n", 0), 4: "Alaala ng isang maulang araw.", 5: "Sa tindahan, may kwento ang bawat suki."}.get(day, "May puwang pa para sa susunod na alaala.")
	var result := _result(day)
	medal.material = null
	medal.texture = null
	medal_title.text = MEDAL_NAMES[day - 1] if not result.is_empty() else "???"
	if not result.is_empty():
		medal.texture = load("res://assets/sprites/ui/daily_medals/day_%d.png" % day)
		if result != "earned":
			var grayscale := ShaderMaterial.new()
			grayscale.shader = UNEARNED
			medal.material = grayscale
		goal_label.text = "%s\n%s" % ["NAKAMIT!" if result == "earned" else "HINDI NAKAMIT · Ayos lang, bahagi ng kwento.", GOAL.new(day).title]
	else:
		goal_label.text = "???"
	page_number.text = "ARAW %d  ·  %s" % [day, ["MGA KWENTO", "KOLEKSYON", "ALBUM"][section]]
	book.queue_redraw()

func _choice_text(day: int) -> String:
	if story == null:
		return "Wala pang naitalang desisyon."
	var keys := {1: "day1_play", 2: "day2_overpayment", 3: "day3_candy", 4: "day4_rain", 5: "day5_debt"}
	var descriptions := {
		"play": "Sumama sa mga kalaro.", "stay": "Nanatili sa tindahan.",
		"return": "Itinabi ang ₱50 ni Mang Berting.", "keep": "Ibinulsa muna ang ₱50 ni Mang Berting.",
		"credit": "Pinautang si Paolo ng ₱3.", "free": "Sinagot ang kulang sa bayad ni Paolo.", "no": "Hindi muna ipinabili ang Coke.",
		"join": "Sumama sa laro sa ulan.", "shelter": "Pinatuloy ang mga kaibigan para sumilong.",
		"installments": "Tinanggap ang ₱110; ₱210 ang natitira.", "defer": "Itatanong muna kay Inay; ₱320 pa rin ang utang."
	}
	var value := str(story.choices.get(keys.get(day, ""), ""))
	var result := str(descriptions.get(value, "Walang naitalang desisyon."))
	if day == 3:
		match str(story.choices.get("day3_friends", "")):
			"later": result += "\nNangakong susunod sa laro."
			"stay": result += "\nHindi muna sumama sa laro."
	return result
