extends Control
## Covers the final illustration before revealing the credits underneath.
signal credits_requested

const FONT = preload("res://assets/fonts/Caveat.ttf")
const DESIGN := Vector2(1920, 1080)
var canvas: Control
var animation: Tween

func _ready() -> void:
	name = "EndingTransition"
	z_index = 110
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var paper := ColorRect.new()
	paper.color = Color("fff0cf")
	paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(paper)
	canvas = Control.new()
	canvas.size = DESIGN
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(canvas)
	var title := Label.new()
	title.text = "The End!"
	title.position = Vector2(360, 320)
	title.size = Vector2(1200, 300)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", FONT)
	title.add_theme_font_size_override("font_size", 200)
	title.add_theme_color_override("font_color", Color("63351f"))
	title.pivot_offset = title.size * 0.5
	title.scale = Vector2.ZERO
	title.rotation = -0.12
	canvas.add_child(title)
	var note := Label.new()
	note.text = "Tapos na ang linggo… pero tuloy ang kuwento."
	note.position = Vector2(310, 650)
	note.size = Vector2(1300, 100)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_font_override("font", FONT)
	note.add_theme_font_size_override("font_size", 48)
	note.add_theme_color_override("font_color", Color("875737"))
	note.modulate.a = 0.0
	canvas.add_child(note)
	resized.connect(_layout)
	_layout()
	modulate.a = 0.0
	animation = create_tween()
	animation.tween_property(self, "modulate:a", 1.0, 0.65)
	animation.tween_property(title, "scale", Vector2.ONE, 0.65).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	animation.parallel().tween_property(title, "rotation", -0.035, 0.65)
	animation.tween_property(note, "modulate:a", 1.0, 0.35)
	animation.tween_property(title, "rotation", 0.025, 0.18)
	animation.tween_property(title, "rotation", -0.025, 0.18)
	animation.tween_property(title, "rotation", 0.0, 0.18)
	animation.tween_interval(1.3)
	animation.tween_callback(func(): credits_requested.emit())
	# The new credits fade in behind this paper, avoiding a flash of gameplay.
	animation.tween_interval(0.1)
	animation.tween_property(self, "modulate:a", 0.0, 0.65)
	animation.tween_callback(queue_free)

func _layout() -> void:
	var factor := minf(size.x / DESIGN.x, size.y / DESIGN.y)
	canvas.scale = Vector2.ONE * factor
	canvas.position = (size - DESIGN * factor) * 0.5
