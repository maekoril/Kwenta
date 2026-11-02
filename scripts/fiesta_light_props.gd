extends Control

const LAMP = preload("res://assets/store/fiesta_lampara.png")
const LAMP_RECT := Rect2(190, 302, 120, 180)
const FLAME_POSITION := Vector2(250, 407)

var _halo: GradientTexture2D

func _ready() -> void:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.25, 1.0])
	gradient.colors = PackedColorArray([Color(1.0, 0.70, 0.28, 0.32), Color(1.0, 0.52, 0.15, 0.13), Color(1.0, 0.45, 0.1, 0.0)])
	_halo = GradientTexture2D.new()
	_halo.gradient = gradient
	_halo.fill = GradientTexture2D.FILL_RADIAL
	_halo.fill_from = Vector2(0.5, 0.5)
	_halo.fill_to = Vector2(1.0, 0.5)
	_halo.width = 256
	_halo.height = 256
	queue_redraw()

func _draw() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	if _halo != null:
		draw_texture_rect(_halo, Rect2(FLAME_POSITION - Vector2(190, 190), Vector2(380, 380)), false)
	# Contact shadow seats the lamp on the left wooden pasamano.
	draw_set_transform(Vector2(250, 479), 0.0, Vector2(1.0, 0.17))
	draw_circle(Vector2.ZERO, 45.0, Color(0.0, 0.0, 0.0, 0.5))
	draw_set_transform(Vector2.ZERO)
	draw_texture_rect(LAMP, LAMP_RECT, false)
