extends Control

const COUNTER_ART = preload("res://scripts/counter_art.gd")

var icon_texture: Texture2D

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	queue_redraw()

func _draw() -> void:
	if icon_texture == null:
		return
	var fitted: Rect2 = get_fitted_rect(Vector2(icon_texture.get_size()), size)
	draw_texture_rect(icon_texture, fitted, false)

static func get_fitted_rect(texture_size: Vector2, bounds: Vector2) -> Rect2:
	return COUNTER_ART.fit_texture_rect(texture_size, bounds)
