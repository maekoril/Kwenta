extends Control

signal page_requested(index: int)

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
var viewer: ColorRect
var remembered_pictures: Dictionary = {}
var current_day := 1
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
	var photo_mount := Panel.new()
	photo_mount.position = Vector2(748, 254)
	photo_mount.size = Vector2(539, 334)
	photo_mount.mouse_filter = Control.MOUSE_FILTER_IGNORE
	photo_mount.add_theme_stylebox_override("panel", KwentaStyle.box(Color("fffaf0"), Color("d0bc98"), 0, 0, 2, 1, 5))
	add_child(photo_mount)
	picture = _picture(self, Vector2(760, 268), Vector2(515, 305))
	caption = _label("", Vector2(765, 590), Vector2(500, 80), 25)
	enlarge = Button.new()
	enlarge.text = "TINGNAN NANG MALAKI"
	enlarge.position = Vector2(795, 678)
	enlarge.size = Vector2(440, 48)
	KwentaStyle.style_button(enlarge, KwentaStyle.PAPER_DARK, 22)
	enlarge.pressed.connect(func(): large_picture.texture = picture.texture; viewer.show())
	add_child(enlarge)
	# A viewport-sized lightbox uses the screen, rather than the notebook's page.
	viewer = ColorRect.new()
	viewer.name = "PhotoViewer"
	viewer.color = Color(0.04, 0.025, 0.015, 0.93)
	viewer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	viewer.hide()
	get_parent().get_parent().add_child(viewer)
	viewer.gui_input.connect(_viewer_input)
	large_picture = _picture(viewer, Vector2.ZERO, Vector2.ZERO)
	large_picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	large_picture.offset_left = 40
	large_picture.offset_right = -40
	large_picture.offset_top = 96
	large_picture.offset_bottom = -32
	large_picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var back := Button.new()
	back.text = "×"
	back.tooltip_text = "Bumalik sa album (Esc)"
	back.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	back.position = Vector2(-104, 12)
	back.size = Vector2(88, 72)
	KwentaStyle.style_button(back, KwentaStyle.PAPER_DARK, 40)
	back.pressed.connect(viewer.hide)
	viewer.add_child(back)

func _viewer_input(event: InputEvent) -> void:
	if not ((event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed) or (event is InputEventScreenTouch and event.pressed)):
		return
	if large_picture.texture == null:
		viewer.hide()
		return
	var image_size := large_picture.texture.get_size()
	var fit := minf(large_picture.size.x / image_size.x, large_picture.size.y / image_size.y)
	var drawn_size := image_size * fit
	var drawn_rect := Rect2(large_picture.position + (large_picture.size - drawn_size) * 0.5, drawn_size)
	if not drawn_rect.has_point(event.position):
		viewer.hide()
	viewer.accept_event()

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
	current_day = day
	selected = int(remembered_pictures.get(day, 0))
	viewer.hide()
	for child in thumbnails.get_children():
		thumbnails.remove_child(child)
		child.queue_free()
	var unlocked := 0
	for entry in CATALOG.ENTRIES:
		if entry.day == day:
			entries.append(entry)
	selected = clampi(selected, 0, maxi(entries.size() - 1, 0))
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
		button.pressed.connect(func(): page_requested.emit(i))
		thumbnails.add_child(button)
		button.add_child(preload("res://scripts/notebook_selection.gd").new())
	count.text = "%d / %d alaala · Araw %d" % [unlocked, entries.size(), day] if not entries.is_empty() else "Wala pang larawan para sa araw na ito."
	_refresh()

func _refresh() -> void:
	remembered_pictures[current_day] = selected
	picture.texture = null
	enlarge.visible = false
	if entries.is_empty():
		title.text = "May puwang pa sa album"
		caption.text = "Dito mapupunta ang mga larawang makikita sa kwento."
		return
	_reveal_selection.call_deferred()
	var entry := entries[selected]
	var seen: bool = CATALOG.is_unlocked(story, entry)
	title.text = entry.title if seen else "???"
	caption.text = entry.caption if seen else "???"
	if seen:
		picture.texture = load("res://assets/story/" + entry.file)
		enlarge.visible = true
	for i in range(thumbnails.get_child_count()):
		thumbnails.get_child(i).get_node("SelectionOutline").visible = selected == i
		KwentaStyle.style_button(thumbnails.get_child(i), KwentaStyle.GOLD if selected == i else KwentaStyle.PAPER_DARK, 23)

func _reveal_selection() -> void:
	if visible and selected < thumbnails.get_child_count():
		thumbnail_scroll.ensure_control_visible(thumbnails.get_child(selected))
