extends Control
## Warm light, soft shadows and a little ambient motion for the store.
##
## It draws between the world (z 0-25) and the HUD (z 30), so the paper tags,
## cash tray and dialogue bubble stay clean. Every piece ignores mouse/touch,
## so dragging products and tapping customers works exactly as before.
## F9 (debug builds) toggles the whole thing, so you can compare before/after.

const STOREFRONT_LAYOUT = preload("res://scripts/storefront_layout.gd")

# ---- Tuning (everything is in 1920x1080 space) -------------------------------
const TINT := Color("fff1de")                 # multiplied over the scene; white = no change
const VIGNETTE_COLOR := Color(0.13, 0.07, 0.03)
const VIGNETTE_ALPHA := 0.30                  # darkness at the screen edges
const WINDOW_RECT := Rect2(350, 90, 1220, 360)  # the street opening (approximate)
const GLOW_COLOR := Color(1.0, 0.86, 0.58)
const GLOW_ALPHA := 0.16                      # sunlight spilling in around the window
const GLOW_BREATH_SECONDS := 5.0
const DUST_RECT := Rect2(250, 80, 1420, 480)  # where dust motes float in the light
const DUST_AMOUNT := 28
const SHADOW_COLOR := Color(0.10, 0.05, 0.02)
const SHADOW_ALPHA := 0.40
const SHADOW_WIDTH := 0.95                    # fraction of the product's width
const SHADOW_HEIGHT := 18.0                   # px
const SHADOW_DROP := 2.0                      # px below the product's bottom edge

# Draw order. The store art uses 0-10, customers 5, products 20, locks 25, HUD 30.
const Z_SHADOWS := 15
const Z_TINT := 26
const Z_LIGHT := 27
const Z_VIGNETTE := 28

const SHADOW_TEX_SIZE := Vector2(128.0, 32.0)

var _tint: ColorRect
var _vignette: TextureRect
var _glow: TextureRect
var _dust: CPUParticles2D
var _shadow_layer: Node2D
var _shadow_texture: GradientTexture2D

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2.ZERO
	size = STOREFRONT_LAYOUT.VIEWPORT_SIZE
	_shadow_texture = _radial(_two_stop(Color(SHADOW_COLOR, SHADOW_ALPHA), Color(SHADOW_COLOR, 0.0)), int(SHADOW_TEX_SIZE.x), int(SHADOW_TEX_SIZE.y))
	_shadow_layer = Node2D.new()
	_shadow_layer.z_index = Z_SHADOWS
	add_child(_shadow_layer)
	_build_tint()
	_build_window_glow()
	_build_dust()
	_build_vignette()
	get_viewport().size_changed.connect(_fit_to_view)
	_fit_to_view()

func _unhandled_input(event: InputEvent) -> void:
	if OS.is_debug_build() and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F9:
		visible = not visible

# One shadow per stocked product. Main calls this from _rebuild_product_shelf.
func set_product_shadows(rects: Array) -> void:
	for child in _shadow_layer.get_children():
		child.queue_free()
	for rect_value in rects:
		var rect: Rect2 = rect_value
		if rect.size == Vector2.ZERO:
			continue
		var shadow := Sprite2D.new()
		shadow.texture = _shadow_texture
		shadow.position = Vector2(rect.get_center().x, rect.end.y + SHADOW_DROP)
		shadow.scale = Vector2(rect.size.x * SHADOW_WIDTH / SHADOW_TEX_SIZE.x, SHADOW_HEIGHT / SHADOW_TEX_SIZE.y)
		_shadow_layer.add_child(shadow)

# Hook for rainy days, brownouts, evening, etc. Example: set_mood(Color("9ea6bd"), 1.0, 2.0)
func set_mood(tint: Color, vignette_strength: float = 1.0, seconds: float = 1.0) -> void:
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_tint, "color", tint, seconds)
	tween.tween_property(_vignette, "modulate:a", clampf(vignette_strength, 0.0, 1.0), seconds)

func _build_tint() -> void:
	_tint = ColorRect.new()
	_tint.color = TINT
	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_MUL
	_tint.material = material
	_place(_tint, Rect2(Vector2.ZERO, STOREFRONT_LAYOUT.VIEWPORT_SIZE), Z_TINT)

func _build_window_glow() -> void:
	var glow := TextureRect.new()
	_glow = glow
	glow.texture = _radial(_two_stop(Color(GLOW_COLOR, GLOW_ALPHA), Color(GLOW_COLOR, 0.0)), 256, 128)
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.stretch_mode = TextureRect.STRETCH_SCALE
	glow.material = _additive()
	_place(glow, WINDOW_RECT.grow(160.0), Z_LIGHT)
	var tween := create_tween().set_loops()
	tween.tween_property(glow, "modulate:a", 0.55, GLOW_BREATH_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(glow, "modulate:a", 1.0, GLOW_BREATH_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _build_dust() -> void:
	var dust := CPUParticles2D.new()
	_dust = dust
	dust.position = DUST_RECT.get_center()
	dust.z_index = Z_LIGHT
	dust.amount = DUST_AMOUNT
	dust.lifetime = 10.0
	dust.preprocess = 10.0        # already populated when the store appears
	dust.texture = _radial(_two_stop(Color(1, 1, 1, 1), Color(1, 1, 1, 0)), 16, 16)
	dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	dust.emission_rect_extents = DUST_RECT.size * 0.5
	dust.direction = Vector2(1.0, -0.35)
	dust.spread = 50.0
	dust.gravity = Vector2.ZERO
	dust.initial_velocity_min = 6.0
	dust.initial_velocity_max = 16.0
	dust.scale_amount_min = 0.4
	dust.scale_amount_max = 1.0
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	ramp.colors = PackedColorArray([Color(1.0, 0.93, 0.75, 0.0), Color(1.0, 0.93, 0.75, 0.55), Color(1.0, 0.93, 0.75, 0.0)])
	dust.color_ramp = ramp
	dust.material = _additive()
	add_child(dust)

func _build_vignette() -> void:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	gradient.colors = PackedColorArray([Color(VIGNETTE_COLOR, 0.0), Color(VIGNETTE_COLOR, 0.0), Color(VIGNETTE_COLOR, VIGNETTE_ALPHA)])
	_vignette = TextureRect.new()
	_vignette.texture = _radial(gradient, 256, 144)
	_vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_vignette.stretch_mode = TextureRect.STRETCH_SCALE
	_place(_vignette, Rect2(Vector2.ZERO, STOREFRONT_LAYOUT.VIEWPORT_SIZE), Z_VIGNETTE)

# With Stretch Aspect = expand the screen can be wider than 1920, and the store art
# stretches sideways to fill it. So the tint and vignette cover the whole visible area,
# and the window glow and dust follow the art's horizontal stretch.
func _fit_to_view() -> void:
	var view := Rect2(-global_position, get_viewport_rect().size)
	for overlay in [_tint, _vignette]:
		overlay.position = view.position
		overlay.size = view.size
	var sx := 1.0
	var parent_control := get_parent() as Control
	if parent_control != null:
		sx = parent_control.size.x / STOREFRONT_LAYOUT.VIEWPORT_SIZE.x
	var glow_rect := WINDOW_RECT.grow(160.0)
	_glow.position = Vector2(glow_rect.position.x * sx, glow_rect.position.y)
	_glow.size = Vector2(glow_rect.size.x * sx, glow_rect.size.y)
	_dust.position = Vector2(DUST_RECT.get_center().x * sx, DUST_RECT.get_center().y)
	_dust.emission_rect_extents = Vector2(DUST_RECT.size.x * 0.5 * sx, DUST_RECT.size.y * 0.5)

# Positions an overlay, makes sure it can never block touch, and adds it.
func _place(node: Control, rect: Rect2, z: int) -> void:
	node.position = rect.position
	node.size = rect.size
	node.z_index = z
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(node)

func _additive() -> CanvasItemMaterial:
	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return material

func _two_stop(inner: Color, outer: Color) -> Gradient:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 1.0])
	gradient.colors = PackedColorArray([inner, outer])
	return gradient

func _radial(gradient: Gradient, width: int, height: int) -> GradientTexture2D:
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = width
	texture.height = height
	return texture
