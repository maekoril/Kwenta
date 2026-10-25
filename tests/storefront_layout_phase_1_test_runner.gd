extends SceneTree

const StorefrontLayoutScript = preload("res://scripts/storefront_layout.gd")
const MainScene = preload("res://scenes/main.tscn")
const CustomerActorScene = preload("res://scenes/customer_slot.tscn")
const CustomerSlotScript = preload("res://scripts/customer_slot.gd")
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
	var viewport := Rect2(Vector2.ZERO, StorefrontLayoutScript.VIEWPORT_SIZE)
	for zone_id in expected_zones:
		var zone: Rect2 = StorefrontLayoutScript.get_storefront_zone(zone_id)
		_assert(zone.size.x > 0.0 and zone.size.y > 0.0, "%s exposes a fixed layout zone" % zone_id)
		_assert(viewport.encloses(zone), "%s stays inside the 1920x1080 viewport" % zone_id)
	var left_rail: Rect2 = StorefrontLayoutScript.get_storefront_zone("top_left_rail")
	var right_rail: Rect2 = StorefrontLayoutScript.get_storefront_zone("top_right_rail")
	_assert(left_rail.end.x <= StorefrontLayoutScript.WINDOW_RECT.position.x, "left rail clears the customer window")
	_assert(right_rail.position.x >= StorefrontLayoutScript.WINDOW_RECT.end.x, "right rail clears the customer window")
	_assert(StorefrontLayoutScript.CONTACT_SHADOW_HEIGHT > 0.0, "layout exposes a positive contact-shadow height")
	var countertop: Rect2 = StorefrontLayoutScript.get_storefront_zone("countertop")
	for product_id in ["bread", "eggs"]:
		_assert(countertop.encloses(StorefrontLayoutScript.get_product_slot(product_id)), "%s uses a dedicated countertop slot" % product_id)
	var shelf_row_a: Rect2 = StorefrontLayoutScript.get_storefront_zone("shelf_row_a")
	_assert(shelf_row_a.encloses(StorefrontLayoutScript.get_product_slot("candy")), "candy jar uses the right shelf plank")

func _test_customer_drop_targets_clear_the_overhead_rails() -> void:
	for customer_x in StorefrontLayoutScript.get_customer_x_positions(5):
		var target: Rect2 = StorefrontLayoutScript.get_customer_drop_rect(customer_x)
		_assert(target.position.x >= StorefrontLayoutScript.WINDOW_RECT.position.x and target.end.x <= StorefrontLayoutScript.WINDOW_RECT.end.x, "customer target remains inside the centre window")
		_assert(is_equal_approx(target.position.y, StorefrontLayoutScript.CUSTOMER_Y) and target.end.y >= StorefrontLayoutScript.WINDOW_RECT.end.y, "customer target includes the lower body behind the sill")

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
			_assert(Rect2(Vector2.ZERO, StorefrontLayoutScript.VIEWPORT_SIZE).encloses(marker.get_rect()), "%s stays inside the main-scene viewport" % node_name)
	var sill := main.get_node_or_null("ForegroundCounterSill") as TextureRect
	_assert(sill != null, "main scene contains a concrete-sill foreground overlay")
	if sill != null:
		_assert(sill.get_rect().end.y >= StorefrontLayoutScript.VIEWPORT_SIZE.y, "foreground sill reaches the bottom edge of the viewport")
	get_root().add_child(main)
	await process_frame
	var customer_layer := main.get("customer_layer") as Control
	var product_layer := main.get("product_layer") as Control
	_assert(customer_layer != null and sill != null and customer_layer.z_index < sill.z_index, "foreground sill renders above the initialized customer layer")
	_assert(product_layer != null and sill != null and sill.z_index < product_layer.z_index, "product shelf renders above the foreground sill")
	main.queue_free()

func _test_customer_actor_compacts_orders_and_keeps_its_drop_target_whole() -> void:
	var actor := CustomerActorScene.instantiate() as Control
	actor.size = Vector2(StorefrontLayoutScript.CUSTOMER_WIDTH, StorefrontLayoutScript.CUSTOMER_HEIGHT)
	get_root().add_child(actor)
	await process_frame
	actor.call("set_customer", CustomerStateScript.new("aleng_mila", OrderStateScript.new({"chips": 1}), 20.0, 100.0), {})
	await process_frame
	var bubble := actor.get_node_or_null("OrderBubble") as PanelContainer
	var content: VBoxContainer = null
	var patience: ProgressBar = null
	var tag: PanelContainer = null
	var grid: GridContainer = null
	if bubble != null:
		content = bubble.get_node_or_null("BubbleContent") as VBoxContainer
	if content != null:
		patience = content.get_node_or_null("PatienceBar") as ProgressBar
		tag = content.get_node_or_null("NameTag") as PanelContainer
		grid = content.get_node_or_null("OrderGrid") as GridContainer
	var portrait := actor.get_node_or_null("Portrait") as TextureRect
	_assert(bubble != null and bubble.size == Vector2(152.0, 134.0), "a one-item order uses the readable-name minimum width and footer rows")
	_assert(content != null and patience != null and tag != null and grid != null, "bubble contains dedicated icon, name, and patience rows")
	_assert(tag != null and grid != null and tag.position.y >= grid.get_rect().end.y, "name row sits below the icon grid")
	_assert(patience != null and tag != null and patience.position.y >= tag.get_rect().end.y, "patience row sits below the name row")
	_assert(portrait != null and portrait.position.y + StorefrontLayoutScript.CUSTOMER_Y < StorefrontLayoutScript.WINDOW_RECT.end.y and portrait.get_rect().end.y + StorefrontLayoutScript.CUSTOMER_Y >= StorefrontLayoutScript.WINDOW_RECT.end.y, "raised customer bust stays visible while its lower body reaches the sill")
	if bubble == null or patience == null:
		actor.queue_free()
		return
	actor.call("set_customer", CustomerStateScript.new("aleng_mila", OrderStateScript.new({"chips": 1, "soft_drink": 1, "instant_noodles": 1, "candy": 1}), 20.0, 100.0), {})
	await process_frame
	_assert(bubble.size == Vector2(184.0, 218.0), "four products use two icon rows above the name and patience footer rows")
	_assert(patience.position.y >= tag.get_rect().end.y, "patience row follows the second icon row without overlap")
	var drop_target := Rect2(Vector2.ZERO, actor.size)
	var patience_rect := Rect2(bubble.position + content.position + patience.position, patience.size)
	_assert(drop_target.encloses(bubble.get_rect()) and drop_target.encloses(patience_rect) and drop_target.encloses(portrait.get_rect()), "actor drop target encloses bubble, bust, and patience bar")
	actor.queue_free()

func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error("Assertion failed: %s" % message)
