class_name WindowRain
extends Control

@export_range(1, 40, 1) var drop_count := 18

var _drops: Array[Dictionary] = []
var _elapsed := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rng := RandomNumberGenerator.new()
	rng.seed = 704
	for index in range(drop_count):
		_drops.append({
			"x": rng.randf(),
			"y": rng.randf(),
			"length": rng.randf_range(16.0, 34.0),
			"speed": rng.randf_range(80.0, 145.0),
			"alpha": rng.randf_range(0.16, 0.31),
		})
	queue_redraw()

func _process(delta: float) -> void:
	_elapsed += delta
	queue_redraw()

func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	for drop in _drops:
		var x := float(drop.x) * size.x
		var y := fposmod(float(drop.y) * size.y + _elapsed * float(drop.speed), size.y + float(drop.length)) - float(drop.length)
		var end := Vector2(x - float(drop.length) * 0.16, y + float(drop.length))
		draw_line(Vector2(x, y), end, Color(0.78, 0.86, 1.0, float(drop.alpha)), 1.0, true)
