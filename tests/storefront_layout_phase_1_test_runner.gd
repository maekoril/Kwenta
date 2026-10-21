extends SceneTree

const StorefrontLayoutScript = preload("res://scripts/storefront_layout.gd")
const MainScene = preload("res://scenes/main.tscn")
const CustomerActorScene = preload("res://scenes/customer_slot.tscn")
const CustomerStateScript = preload("res://scripts/customer_state.gd")
const OrderStateScript = preload("res://scripts/order_state.gd")

var failures: int = 0

func _initialize() -> void:
	_test_storefront_zones_keep_items_in_the_playable_viewport()
	_test_customer_drop_targets_clear_the_overhead_rails()
	await _test_main_scene_exposes_slot_markers_and_foreground_sill()
	await _test_customer_actor_compacts_orders_and_keeps_its_drop_target_whole()
	if failures > 0:
		push_error("%d storefront layout Phase 1 assertion(s) failed." % failures)
		quit(1)
	else:
		print("All storefront layout Phase 1 assertions passed.")
		quit(0)

func _test_storefront_zones_keep_items_in_the_playable_viewport() -> void:
	var expected_zones := ["top_left_rail", "top_right_rail", "countertop", "shelf_row_a", "shelf_row_b"]
	var viewport := Rect2(Vector2.ZERO, Vector2(640.0, 360.0))
	for zone_id in expected_zones:
		var zone: Rect2 = StorefrontLayoutScript.get_storefront_zone(zone_id)
		_assert(zone.size.x > 0.0 and zone.size.y > 0.0, "%s exposes a fixed layout zone" % zone_id)
		_assert(viewport.encloses(zone), "%s stays inside the 640x360 viewport" % zone_id)
	_assert(is_equal_approx(StorefrontLayoutScript.get_storefront_zone("top_left_rail").position.y, 24.0), "left rail begins at the hook line")
	_assert(is_equal_approx(StorefrontLayoutScript.get_storefront_zone("top_right_rail").end.y, 84.0), "right rail ends before the customer window")
	_assert(StorefrontLayoutScript.CONTACT_SHADOW_HEIGHT >= 1.0 and StorefrontLayoutScript.CONTACT_SHADOW_HEIGHT <= 2.0, "layout exposes a 1-2px contact-shadow height")
	var countertop: Rect2 = StorefrontLayoutScript.get_storefront_zone("countertop")
	for product_id in ["bread", "eggs"]:
		_assert(countertop.encloses(StorefrontLayoutScript.get_product_slot(product_id)), "%s uses a dedicated countertop slot" % product_id)
	var shelf_row_a: Rect2 = StorefrontLayoutScript.get_storefront_zone("shelf_row_a")
	_assert(shelf_row_a.encloses(StorefrontLayoutScript.get_product_slot("candy")), "candy jar uses the right shelf plank")

func _test_customer_drop_targets_clear_the_overhead_rails() -> void:
	for customer_x in StorefrontLayoutScript.get_customer_x_positions(5):
		var target: Rect2 = StorefrontLayoutScript.get_customer_drop_rect(customer_x)
		_assert(target.position.x >= 150.0 and target.end.x <= 490.0, "customer target remains inside the centre window")
		_assert(is_equal_approx(target.position.y, 31.0) and is_equal_approx(target.end.y, 206.0), "raised customer target includes the bubble and occluded lower body")

func _test_main_scene_exposes_slot_markers_and_foreground_sill() -> void:
	var main := MainScene.instantiate()
	var layout_root := main.get_node_or_null("StorefrontLayout") as Control
	_assert(layout_root != null, "main scene contains the storefront layout root")
	var markers := {
		"CustomerWindow": "customer_window",
		"TopLeftRailSlots": "top_left_rail",
		"TopRightRailSlots": "top_right_rail",
		"CountertopSlots": "countertop",
		"ShelfRowASlots": "shelf_row_a",
		"ShelfRowBSlots": "shelf_row_b",
	}
	for node_name in markers:
		var marker := main.get_node_or_null("StorefrontLayout/%s" % node_name) as Control
		_assert(marker != null, "%s marker exists in the scene tree" % node_name)
		if marker != null:
			var expected_zone: Rect2 = StorefrontLayoutScript.get_storefront_zone(str(markers[node_name]))
			_assert(marker.position == expected_zone.position and marker.size == expected_zone.size, "%s matches the layout model" % node_name)
	var sill := main.get_node_or_null("ForegroundCounterSill") as TextureRect
	_assert(sill != null, "main scene contains a concrete-sill foreground overlay")
	if sill != null:
		_assert(is_equal_approx(sill.position.y, 176.0), "foreground sill begins at the concrete surface")
	get_root().add_child(main)
	await process_frame
	var customer_layer := main.get("customer_layer") as Control
	var product_layer := main.get("product_layer") as Control
	_assert(customer_layer != null and sill != null and customer_layer.z_index < sill.z_index, "foreground sill renders above the initialized customer layer")
	_assert(product_layer != null and sill != null and sill.z_index < product_layer.z_index, "product shelf renders above the foreground sill")
	main.queue_free()

func _test_customer_actor_compacts_orders_and_keeps_its_drop_target_whole() -> void:
	var authored_actor := CustomerActorScene.instantiate() as Control
	_assert(authored_actor.size == Vector2(68.0, 175.0), "customer scene has a raised bust and bubble hit-target height")
	authored_actor.queue_free()
	var actor := CustomerActorScene.instantiate() as Control
	actor.size = Vector2(StorefrontLayoutScript.CUSTOMER_WIDTH, StorefrontLayoutScript.CUSTOMER_HEIGHT)
	get_root().add_child(actor)
	await process_frame
	actor.call("set_customer", CustomerStateScript.new("aleng_mila", OrderStateScript.new({"chips": 1}), 20.0, 100.0), {})
	await process_frame
	var bubble := actor.get_node_or_null("OrderBubble") as PanelContainer
	var patience := actor.get_node_or_null("PatienceBar") as ProgressBar
	var tag := actor.get_node_or_null("NameTrustTag") as PanelContainer
	var portrait := actor.get_node_or_null("Portrait") as TextureRect
	_assert(bubble != null and bubble.size == Vector2(24.0, 24.0), "a one-item order uses a tight 20px-icon bubble")
	_assert(patience != null and is_equal_approx(patience.position.y, bubble.position.y + bubble.size.y + 1.0), "patience bar sits directly under the compact bubble")
	_assert(tag != null, "customer name and trust use a pill container")
	_assert(portrait != null and is_equal_approx(portrait.position.y + StorefrontLayoutScript.CUSTOMER_Y, 94.0) and is_equal_approx(portrait.get_rect().end.y + StorefrontLayoutScript.CUSTOMER_Y, 206.0), "raised customer bust stays visible while its lower body reaches the sill")
	_assert(bubble != null and portrait != null and is_equal_approx(bubble.get_rect().end.y, portrait.position.y - 15.0), "compact bubble sits 15px above the customer head")
	_assert(tag != null and patience != null and portrait != null and tag.position.y >= patience.get_rect().end.y and tag.get_rect().end.y <= portrait.position.y, "name tag sits under the bubble without covering the face")
	if bubble == null or patience == null:
		actor.queue_free()
		return
	actor.call("set_customer", CustomerStateScript.new("aleng_mila", OrderStateScript.new({"chips": 1, "soft_drink": 1, "instant_noodles": 1, "candy": 1}), 20.0, 100.0), {})
	await process_frame
	_assert(bubble.size == Vector2(64.0, 44.0), "four products use two compact icon rows without beige padding")
	_assert(is_equal_approx(patience.position.y, bubble.position.y + bubble.size.y + 1.0), "patience bar follows a second bubble row")
	_assert(portrait != null and is_equal_approx(bubble.get_rect().end.y, portrait.position.y - 15.0), "multi-item bubble stays 15px above the customer head")
	var drop_target := Rect2(Vector2.ZERO, actor.size)
	_assert(drop_target.encloses(bubble.get_rect()) and drop_target.encloses(patience.get_rect()) and drop_target.encloses(portrait.get_rect()), "actor drop target encloses bubble, bust, and patience bar")
	actor.queue_free()

func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error("Assertion failed: %s" % message)
