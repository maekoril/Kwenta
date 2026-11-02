extends Control

const CATALOG = preload("res://scripts/illustration_catalog.gd")
var story
var entries: Array[Dictionary] = []
var selected := 0
var thumbnails: VBoxContainer
var thumbnail_scroll: ScrollContainer
var picture: TextureRect
var caption: Label
var title: Label
var count: Label
var enlarge: Button
var viewer: Panel
var large_picture: TextureRect

func _ready() -> void:
	_label("MGA LARAWANG NAITABI", Vector2(100, 171), Vector2(510, 40), 24)
	count = _label("", Vector2(100, 216), Vector2(510, 45), 22)
	thumbnail_scroll = preload("res://scripts/notebook_scroll.gd").new()
	thumbnail_scroll.name = "ThumbnailScroll"
	thumbnail_scroll.position = Vector2(100, 278)
	thumbnail_scroll.size = Vector2(510, 405)
	thumbnail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	thumbnail_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	add_child(thumbnail_scroll)
	thumbnails = VBoxContainer.new()
	thumbnails.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	thumbnails.add_theme_constant_override("separation", 8)
	thumbnail_scroll.add_child(thumbnails)
	title = _label("", Vector2(765, 177), Vector2(500, 65), 29)
	picture = _picture(self, Vector2(760, 268), Vector2(515, 305))
	caption = _label("", Vector2(765, 590), Vector2(500, 80), 25)
	enlarge = Button.new()
	enlarge.text = "TINGNAN NANG MALAKI"
	enlarge.position = Vector2(795, 678)
	enlarge.size = Vector2(440, 48)
	KwentaStyle.style_button(enlarge, KwentaStyle.PAPER_DARK, 22)
	enlarge.pressed.connect(func(): large_picture.texture = picture.texture; viewer.show())
	add_child(enlarge)
	viewer = Panel.new()
	viewer.position = Vector2(65, 145)
	viewer.size = Vector2(1260, 595)
	viewer.add_theme_stylebox_override("panel", KwentaStyle.box(KwentaStyle.PAPER, KwentaStyle.INK, 0, 0, 4, 3, 4))
	viewer.hide()
	add_child(viewer)
	large_picture = _picture(viewer, Vector2(20, 20), Vector2(1220, 495))
	var back := Button.new()
	back.text = "< BUMALIK SA ALBUM"
	back.position = Vector2(440, 527)
	back.size = Vector2(380, 52)
	KwentaStyle.style_button(back, KwentaStyle.PAPER_DARK, 22)
	back.pressed.connect(viewer.hide)
	viewer.add_child(back)

func _label(text: String, at: Vector2, bounds: Vector2, font_size: int) -> Label:
	var label := KwentaStyle.make_label(text, font_size, KwentaStyle.INK)
	label.position = at
	label.size = bounds
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(label)
	return label

func _picture(parent: Control, at: Vector2, bounds: Vector2) -> TextureRect:
	var texture := TextureRect.new()
	texture.position = at
	texture.size = bounds
	texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	parent.add_child(texture)
	return texture

func show_day(progress, day: int) -> void:
	story = progress
	entries.clear()
	selected = 0
	viewer.hide()
	for child in thumbnails.get_children():
		thumbnails.remove_child(child)
		child.queue_free()
	var unlocked := 0
	for entry in CATALOG.ENTRIES:
		if entry.day == day:
			entries.append(entry)
	for i in range(entries.size()):
		var entry := entries[i]
		var seen: bool = CATALOG.is_unlocked(story, entry)
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 90)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.text = entry.title if seen else "???"
		if seen:
			unlocked += 1
			button.icon = load("res://assets/story/" + entry.file)
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 160)
		KwentaStyle.style_button(button, KwentaStyle.PAPER_DARK, 23)
		button.pressed.connect(func(): selected = i; _refresh())
		thumbnails.add_child(button)
	count.text = "%d / %d alaala · Araw %d" % [unlocked, entries.size(), day] if not entries.is_empty() else "Wala pang larawan para sa araw na ito."
	_refresh()

func _refresh() -> void:
	picture.texture = null
	enlarge.visible = false
	if entries.is_empty():
		title.text = "May puwang pa sa album"
		caption.text = "Dito mapupunta ang mga larawang makikita sa kwento."
		return
	var entry := entries[selected]
	var seen: bool = CATALOG.is_unlocked(story, entry)
	title.text = entry.title if seen else "???"
	caption.text = entry.caption if seen else "???"
	if seen:
		picture.texture = load("res://assets/story/" + entry.file)
		enlarge.visible = true
	for i in range(thumbnails.get_child_count()):
		KwentaStyle.style_button(thumbnails.get_child(i), KwentaStyle.GOLD if selected == i else KwentaStyle.PAPER_DARK, 23)
