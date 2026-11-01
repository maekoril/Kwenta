extends Control

const UNEARNED = preload("res://shaders/unearned_medal.gdshader")
const GOAL = preload("res://scripts/daily_goal.gd")
const PAGE = preload("res://scripts/diary_page.gd")
const BINDING = preload("res://scripts/diary_binding.gd")
const HANDWRITING = preload("res://assets/fonts/Caveat.ttf")
var story
var days: Array[int] = []
var page_index := 0
var heading: Label
var entry_label: Label
var choice_label: Label
var goal_label: Label
var medal: TextureRect
var previous_button: Button
var next_button: Button

func _ready() -> void:
	name = "DiaryReader"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.65)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(1250, 700)
	panel.add_theme_stylebox_override("panel", KwentaStyle.box(Color("795035"), Color("39251c"), 30.0, 26.0, 12, 6, 8))
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	panel.add_child(column)
	heading = KwentaStyle.make_label("KUWADERNO", 38, Color("f8e5c4"))
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(heading)
	var pages := HBoxContainer.new()
	pages.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pages.add_theme_constant_override("separation", 0)
	column.add_child(pages)
	var left := _make_page(pages, "KWENTO NI TONYO")
	entry_label = KwentaStyle.make_label("", 46, KwentaStyle.INK)
	entry_label.add_theme_font_override("font", HANDWRITING)
	entry_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(entry_label)
	var binding := BINDING.new()
	binding.custom_minimum_size.x = 48
	pages.add_child(binding)
	var right := _make_page(pages, "BALIK-TANAW")
	choice_label = KwentaStyle.make_label("", 30, KwentaStyle.INK)
	choice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(choice_label)
	goal_label = KwentaStyle.make_label("", 29, KwentaStyle.INK)
	goal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(goal_label)
	medal = TextureRect.new()
	medal.custom_minimum_size = Vector2(150, 150)
	medal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	medal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	medal.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(medal)
	var navigation := HBoxContainer.new()
	navigation.alignment = BoxContainer.ALIGNMENT_CENTER
	navigation.add_theme_constant_override("separation", 20)
	column.add_child(navigation)
	previous_button = _button("< NAKARAAN", navigation)
	previous_button.pressed.connect(func(): _flip(-1))
	var close_button := _button("ISARA", navigation)
	close_button.pressed.connect(close)
	next_button = _button("SUSUNOD >", navigation)
	next_button.pressed.connect(func(): _flip(1))

func _make_page(parent: Control, title: String) -> VBoxContainer:
	var page := PanelContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_stylebox_override("panel", KwentaStyle.box(Color("faedcf"), Color("d4b78c"), 36.0, 28.0, 3, 2, 0))
	parent.add_child(page)
	var column := PAGE.new()
	column.add_theme_constant_override("separation", 22)
	page.add_child(column)
	var label := KwentaStyle.make_label(title, 23, Color("765137"))
	column.add_child(label)
	return column

func _button(label: String, parent: Control) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(220, 65)
	KwentaStyle.style_button(button, KwentaStyle.PAPER_DARK, 22)
	parent.add_child(button)
	return button

func open(progress) -> void:
	story = progress
	days.clear()
	if story != null:
		for day in range(1, 8):
			if not str(story.choices.get("diary_day_%d" % day, "")).is_empty():
				days.append(day)
	page_index = maxi(days.size() - 1, 0)
	_refresh()
	visible = true

func close() -> void:
	visible = false

func _flip(direction: int) -> void:
	page_index = clampi(page_index + direction, 0, maxi(days.size() - 1, 0))
	_refresh()

func _refresh() -> void:
	previous_button.disabled = days.is_empty() or page_index == 0
	next_button.disabled = days.is_empty() or page_index >= days.size() - 1
	if days.is_empty():
		heading.text = "KUWADERNO"
		entry_label.text = "Wala pang naisusulat si Tonyo. Matapos ang araw, dito niya ibabahagi ang kanyang kwento."
		choice_label.text = "Dito rin makikita ang mga desisyon niya."
		goal_label.text = ""
		medal.texture = null
		return
	var day: int = days[page_index]
	heading.text = "KUWADERNO  ·  DAY %d" % day
	entry_label.text = str(story.choices.get("diary_day_%d" % day, ""))
	choice_label.text = "PINILI NI TONYO\n" + _choice_text(day)
	var result := str(story.choices.get("diary_goal_day_%d" % day, ""))
	medal.material = null
	medal.texture = null
	if result == "earned" or result == "missed":
		var goal = GOAL.new(day)
		goal_label.text = "DAILY GOAL\n%s\n%s" % [goal.title, "Nakamit!" if result == "earned" else "Hindi nakamit"]
		medal.texture = load("res://assets/sprites/ui/daily_medals/day_%d.png" % day) as Texture2D
		if result == "missed":
			var grayscale := ShaderMaterial.new()
			grayscale.shader = UNEARNED
			medal.material = grayscale
	else:
		goal_label.text = "DAILY GOAL\nWalang naitalang resulta para sa araw na ito."

func _choice_text(day: int) -> String:
	var keys := {1: "day1_play", 2: "day2_overpayment", 3: "day3_candy", 4: "day4_rain"}
	var descriptions := {
		"play": "Sumama sa mga kalaro.", "stay": "Nanatili sa tindahan.",
		"return": "Itinabi ang ₱50 ni Mang Berting.", "keep": "Ibinulsa muna ang ₱50 ni Mang Berting.",
		"credit": "Pinautang si Paolo ng ₱3.", "free": "Sinagot ang kulang sa bayad ni Paolo.", "no": "Hindi muna ipinabili ang Feeta.",
		"join": "Sumama sa laro sa ulan.", "shelter": "Pinatuloy ang mga kaibigan para sumilong."
	}
	var value := str(story.choices.get(keys.get(day, ""), ""))
	var result := str(descriptions.get(value, "Walang naitalang desisyon."))
	if day == 3:
		match str(story.choices.get("day3_friends", "")):
			"later": result += "\nNangakong susunod sa laro."
			"stay": result += "\nHindi muna sumama sa laro."
	return result
