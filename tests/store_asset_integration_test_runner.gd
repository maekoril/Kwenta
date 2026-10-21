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
	_assert(main_scene.get_node_or_null("CandyJarFixture") != null, "candy jar is layered into the main scene")
	var product_layer: Control = main_scene.get("product_layer")
	var candy_jar: Control = main_scene.get_node_or_null("CandyJarFixture")
	if candy_jar != null:
		_assert(candy_jar.get_index() > product_layer.get_index(), "jar glass draws in front of gum packs")
	for product_id in ["coffee_sachet", "juice_sachet", "iced_tea_sachet", "shampoo_sachet", "toothpaste_sachet", "laundry_sachet"]:
		var strip: Texture2D = COUNTER_ART.product_display_texture(product_id)
		_assert(strip is AtlasTexture and strip.get_size().y > strip.get_size().x * 2.0, "%s hangs as a tight vertical sachet strip" % product_id)
	for product_id in ["chips", "biscuits", "bottled_water", "coffee_sachet", "juice_sachet", "iced_tea_sachet", "shampoo_sachet", "toothpaste_sachet", "laundry_sachet", "canned_sardines", "bread", "rice"]:
		var grouped_texture: Texture2D = COUNTER_ART.product_display_texture(product_id)
		_assert(grouped_texture != null, "%s grouped display sprite loads" % product_id)
	for product_id in ["instant_noodles", "eggs", "soy_sauce", "vinegar", "fish_sauce"]:
		var single_texture: Texture2D = COUNTER_ART.product_single_texture(product_id)
		_assert(single_texture != null, "%s single-item drag sprite loads" % product_id)
	var product_items: Dictionary = main_scene.get("product_items_by_id")
	_assert(product_items.has("instant_noodles"), "Day 1 noodle product exists in the actual store scene")
	_assert(product_items.has("soft_drink"), "Day 1 drink product exists in the actual store scene")
	var noodles: Control = product_items.get("instant_noodles")
	var drink: Control = product_items.get("soft_drink")
	if noodles != null:
		var single_texture: Texture2D = noodles.get("_item_icon")
		var display_texture: Texture2D = noodles.get("_display_texture")
		var store_size: Vector2 = noodles.call("_get_store_display_size")
		var preview_size: Vector2 = noodles.call("_get_drag_preview_size")
		_assert(store_size.distance_to(Vector2(53.2, 49.0)) < 0.01, "in-store grouped noodle art renders at 1.4x its layout size")
		_assert(preview_size.distance_to(Vector2(45.6, 42.0)) < 0.01, "drag preview remains based on the compact layout size")
		_assert(single_texture != null, "dragging noodles uses the single-item Nissin sprite")
		_assert(display_texture is AtlasTexture and (display_texture as AtlasTexture).region.size.x < 210.0, "shelf stock trims transparent padding from the grouped noodle sprite")
	if drink != null:
		var single_texture: Texture2D = drink.get("_item_icon")
		var display_texture: Texture2D = drink.get("_display_texture")
		_assert(single_texture != null and single_texture.get_size() == Vector2(180.0, 240.0), "dragging a drink uses one Coke bottle sprite")
		_assert(display_texture is AtlasTexture and (display_texture as AtlasTexture).atlas.get_size() == Vector2(210.0, 276.0), "cooler stock uses the grouped Coke crate sprite")
		_assert(int(drink.get("_stock_count")) == 3, "Coke crates repeat across the cooler well")
	_assert(product_items.has("candy"), "candy stock appears in the jar")
	if product_items.has("candy"):
		var candy: Control = product_items["candy"]
		_assert(candy.position.y > 200.0, "candy is placed inside the counter jar rather than on a hanger")
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
