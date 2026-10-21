extends SceneTree

const MainScene = preload("res://scenes/main.tscn")
const ProductDragItemScene = preload("res://scenes/product_drag_item.tscn")
const STORE_BACKGROUND = preload("res://assets/backgrounds/kwenta_store_interior_clean.png")
const StorefrontLayoutScript = preload("res://scripts/storefront_layout.gd")

var failures := 0

func _initialize() -> void:
	_run_tests()

func _run_tests() -> void:
	var main := MainScene.instantiate() as Control
	root.add_child(main)
	await process_frame
	var full_backgrounds: Array[TextureRect] = []
	for child in main.get_children():
		if child is TextureRect:
			var texture_rect := child as TextureRect
			if texture_rect.texture == STORE_BACKGROUND and texture_rect.position == Vector2.ZERO and texture_rect.size == Vector2(640.0, 360.0):
				full_backgrounds.append(texture_rect)
	_assert(full_backgrounds.size() == 1, "the main scene draws exactly one full 640x360 store background")
	var background := main.get_node_or_null("StoreBackground") as TextureRect
	_assert(background != null, "the scene owns an explicit StoreBackground node")
	if background != null:
		_assert(background.position == Vector2.ZERO and background.size == Vector2(640.0, 360.0), "StoreBackground is anchored at the 640x360 design origin")
		_assert(background.texture_repeat == CanvasItem.TEXTURE_REPEAT_DISABLED, "StoreBackground disables texture repetition")
		_assert(background.expand_mode == TextureRect.EXPAND_IGNORE_SIZE and background.stretch_mode == TextureRect.STRETCH_SCALE, "StoreBackground scales a single texture frame")
	var sill := main.get_node_or_null("ForegroundCounterSill") as TextureRect
	var sill_crop := sill.texture as AtlasTexture if sill != null else null
	_assert(sill_crop != null and sill_crop.region.position.y > 0.0, "foreground sill draws only the lower background crop")
	main.queue_free()
	_assert_slot_rests_on_plank("instant_noodles", 185.0, 268.0, "Noodle Cups")
	_assert_slot_rests_on_plank("biscuits", 238.0, 268.0, "Fita")
	_assert_slot_rests_on_plank("candy", 462.0, 265.0, "Candy Jar")
	_assert_slot_rests_on_plank("bottled_water", 280.0, 328.0, "Bottled Water Crate")
	_assert_slot_rests_on_plank("soft_drink", 80.0, 330.0, "Red Soda Cooler")

	var product_drag_item := ProductDragItemScene.instantiate() as Control
	root.add_child(product_drag_item)
	await process_frame
	_assert(product_drag_item.tooltip_text.is_empty(), "active product items do not show a tutorial tooltip over the counter")
	product_drag_item.queue_free()

	if failures > 0:
		push_error("%d storefront background regression assertion(s) failed." % failures)
		quit(1)
	else:
		print("Storefront background regression assertions passed.")
		quit(0)

func _assert(condition: bool, description: String) -> void:
	if condition:
		return
	failures += 1
	push_error("FAIL: " + description)

func _assert_slot_rests_on_plank(product_id: String, x: float, baseline_y: float, label: String) -> void:
	var slot: Rect2 = StorefrontLayoutScript.get_product_slot(product_id)
	_assert(is_equal_approx(slot.position.x, x) and is_equal_approx(slot.end.y, baseline_y), "%s rests in its requested shelf compartment" % label)
