extends SceneTree

const COUNTER_ART = preload("res://scripts/counter_art.gd")

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	var main_scene := load("res://scenes/main.tscn").instantiate() as Control
	root.add_child(main_scene)
	await process_frame
	_assert(ResourceLoader.exists("res://assets/backgrounds/kwenta_store_interior_clean.png"), "clean in-store background is available")
	_assert(ResourceLoader.exists("res://assets/sprites/fixtures/candy_jar_empty.png"), "empty candy jar is a separate sprite")
	_assert(main_scene.get_node_or_null("CoolerFixture") == null and main_scene.get_node_or_null("CoolerFront") == null, "empty cooler artwork is removed from the bottom-left shelf")
	var product_layer: Control = main_scene.get("product_layer")
	_assert(product_layer != null, "main scene exposes the product display layer")
	for product_id in ["coffee_sachet", "juice_sachet", "iced_tea_sachet", "shampoo_sachet", "toothpaste_sachet", "laundry_sachet"]:
		var strip: Texture2D = COUNTER_ART.product_display_texture(product_id)
		_assert(strip != null and strip.resource_path.begins_with("res://assets/products/sachets/") and strip.get_size().y > strip.get_size().x * 2.0, "%s uses a tall authored PNG sachet strip" % product_id)
	for product_id in ["chips", "biscuits", "bottled_water", "coffee_sachet", "juice_sachet", "iced_tea_sachet", "shampoo_sachet", "toothpaste_sachet", "laundry_sachet", "canned_sardines", "bread", "rice"]:
		var grouped_texture: Texture2D = COUNTER_ART.product_display_texture(product_id)
		_assert(grouped_texture != null, "%s grouped display sprite loads" % product_id)
	for product_id in ["instant_noodles", "eggs", "soy_sauce", "vinegar", "fish_sauce"]:
		var single_texture: Texture2D = COUNTER_ART.product_single_texture(product_id)
		_assert(single_texture != null, "%s single-item drag sprite loads" % product_id)
	var product_items: Dictionary = main_scene.get("product_items_by_id")
	_assert(product_items.has("instant_noodles"), "Day 1 noodle product exists in the actual store scene")
	var noodles: Control = product_items.get("instant_noodles")
	if noodles != null:
		var single_texture: Texture2D = noodles.get("_item_icon")
		var display_texture: Texture2D = noodles.get("_display_texture")
		var store_size: Vector2 = noodles.call("_get_store_display_size")
		var preview_size: Vector2 = noodles.call("_get_drag_preview_size")
		_assert(store_size.x > preview_size.x and store_size.y > preview_size.y, "in-store grouped noodle art renders larger than its single-item drag preview")
		_assert(single_texture != null, "dragging noodles uses the single-item Nissin sprite")
		_assert(display_texture != null and display_texture.resource_path.begins_with("res://assets/products/shelf_goods/"), "shelf stock uses the authored Noodz PNG")
	if failures > 0:
		push_error("%d store asset integration assertion(s) failed." % failures)
		quit(1)
	else:
		print("Store asset integration assertions passed.")
		quit(0)

func _assert(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + description)
