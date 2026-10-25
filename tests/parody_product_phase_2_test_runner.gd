extends SceneTree

const CampaignConfig = preload("res://data/story/summer_campaign.tres")
const CampaignStateScript = preload("res://scripts/campaign_state.gd")
const CounterArt = preload("res://scripts/counter_art.gd")
const CustomerActorScene = preload("res://scenes/customer_slot.tscn")
const CustomerStateScript = preload("res://scripts/customer_state.gd")
const OrderStateScript = preload("res://scripts/order_state.gd")
const ProductAtlas = preload("res://assets/sprites/kwenta_generic_products.png")
const ProductDragItemScene = preload("res://scenes/product_drag_item.tscn")
const StorefrontLayout = preload("res://scripts/storefront_layout.gd")

const EXPECTED_PRODUCTS := {
	"juice_sachet": {"name": "Thang", "price": 12, "zone": "top_left_rail", "mark": "citrus"},
	"iced_tea_sachet": {"name": "Zesty", "price": 12, "zone": "top_left_rail", "mark": "leaf"},
	"coffee_sachet": {"name": "Kapeko Blanca", "price": 7, "zone": "top_left_rail", "mark": "bean"},
	"shampoo_sachet": {"name": "Clean", "price": 12, "zone": "top_right_rail", "mark": "drop"},
	"toothpaste_sachet": {"name": "Rizz-Up Toothpaste", "price": 10, "zone": "top_right_rail", "mark": "tube"},
	"laundry_sachet": {"name": "Champ Powder", "price": 9, "zone": "top_right_rail", "mark": "spark"},
	"chips": {"name": "Patos", "price": 10, "zone": "top_left_rail", "mark": "hex"},
	"biscuits": {"name": "Feeta", "price": 8, "zone": "shelf_row_a"},
	"sandwich_biscuits": {"name": "Wemby", "price": 8, "zone": "shelf_row_a"},
	"bread": {"name": "Bread-winner", "price": 35, "zone": "countertop"},
	"instant_noodles": {"name": "Noodz", "price": 15, "zone": "shelf_row_a"},
	"noodle_pack": {"name": "Ticnap Notnac", "price": 15, "zone": "shelf_row_a"},
	"canned_sardines": {"name": "Giga Sardines", "price": 28, "zone": "shelf_row_a"},
	"candy": {"name": "Maximo", "price": 5, "zone": "shelf_row_a"},
	"bubble_gum": {"name": "B-fresh Gum", "price": 5, "zone": "shelf_row_a"},
	"eggs": {"name": "Egg Large", "price": 12, "zone": "countertop"},
	"soft_drink": {"name": "Cola-Coca", "price": 20, "zone": "shelf_row_b"},
	"bottled_water": {"name": "Bato Spring Water", "price": 12, "zone": "shelf_row_b"},
	"cooking_oil": {"name": "Golden State Warriors Oil", "price": 40, "zone": "shelf_row_b"},
	"soy_sauce": {"name": "Boss Toyo", "price": 18, "zone": "shelf_row_b"},
	"vinegar": {"name": "Real Suka", "price": 18, "zone": "shelf_row_b"},
	"fish_sauce": {"name": "Pating", "price": 18, "zone": "shelf_row_b"},
	"rice": {"name": "Jasmine Rice", "price": 75, "zone": "shelf_row_b"},
}

var failures := 0

func _initialize() -> void:
	_test_catalog_data_and_layout_slots()
	_test_visual_identity_contract()
	await _test_stack_and_single_unit_rendering_contract()
	await _test_order_bubbles_use_single_unit_icons()
	_test_future_products_stay_locked_out_of_stock()
	if failures > 0:
		push_error("%d Phase 2 parody product assertion(s) failed." % failures)
		quit(1)
	else:
		print("All Phase 2 parody product assertions passed.")
		quit(0)

func _test_catalog_data_and_layout_slots() -> void:
	var products_by_id: Dictionary = {}
	for product_resource in CampaignConfig.product_catalog:
		products_by_id[product_resource.id] = product_resource
	_assert(products_by_id.size() == EXPECTED_PRODUCTS.size(), "the campaign catalog registers exactly 23 products")
	for product_id in EXPECTED_PRODUCTS:
		var expected: Dictionary = EXPECTED_PRODUCTS[product_id]
		var product: ProductData = products_by_id.get(product_id)
		_assert(product != null, "%s is registered in the campaign catalog" % product_id)
		if product == null:
			continue
		_assert(product.display_name == expected.name, "%s has its required parody display name" % product_id)
		_assert(product.price == expected.price, "%s keeps its assigned price" % product_id)
		var slot: Rect2 = StorefrontLayout.get_product_slot(product_id)
		var zone: Rect2 = StorefrontLayout.get_storefront_zone(str(expected.zone))
		_assert(slot.size != Vector2.ZERO, "%s has a fixed storefront slot" % product_id)
		_assert(zone.encloses(slot), "%s sits wholly inside its assigned layout zone" % product_id)
		_assert(StorefrontLayout.get_product_layout_zone(product_id) == expected.zone, "%s declares the same named layout zone as its slot" % product_id)
		_assert(StorefrontLayout.get_product_display_size(product_id) != Vector2.ZERO, "%s has a display footprint" % product_id)
		if str(expected.zone).begins_with("top_"):
			_assert(StorefrontLayout.is_hanging_rail_product(product_id), "%s renders as a connected rail strip" % product_id)

func _test_visual_identity_contract() -> void:
	for product_resource in CampaignConfig.product_catalog:
		var product: ProductData = product_resource
		var assigned_single: Texture2D = product.get("single_unit_texture") as Texture2D
		var assigned_stacked: Texture2D = product.get("stacked_texture") as Texture2D
		_assert(assigned_single != null, "%s assigns a single-unit Texture2D in product data" % product.id)
		_assert(assigned_stacked != null, "%s assigns a stacked Texture2D in product data" % product.id)
		_assert(_texture_png_path(assigned_single).begins_with("res://assets/products/"), "%s single unit comes from the product PNG pipeline" % product.id)
		_assert(_texture_png_path(assigned_stacked).begins_with("res://assets/products/"), "%s stacked display comes from the product PNG pipeline" % product.id)
		var single := CounterArt.product_single_texture(product.id)
		var stacked := CounterArt.product_display_texture(product.id)
		_assert(single == assigned_single, "%s drag previews resolve its assigned single-unit PNG texture" % product.id)
		_assert(stacked == assigned_stacked, "%s shelf displays resolve its assigned stacked PNG texture" % product.id)
		_assert(single != stacked, "%s keeps distinct single and stacked texture assets" % product.id)
	var counter_art_source := FileAccess.get_file_as_string("res://scripts/counter_art.gd")
	_assert(not counter_art_source.contains("ImageTexture.create_from_image"), "counter art does not generate ImageTextures at runtime")
	_assert(not counter_art_source.contains("Image.create"), "counter art does not use procedural Image drawing")

func _texture_png_path(texture: Texture2D) -> String:
	if texture == null:
		return ""
	if texture is AtlasTexture:
		return (texture as AtlasTexture).atlas.resource_path
	return texture.resource_path

func _test_stack_and_single_unit_rendering_contract() -> void:
	for product_id in EXPECTED_PRODUCTS:
		var icon := CounterArt.product_icon(product_id, ProductAtlas)
		var single := CounterArt.product_single_texture(product_id)
		var display := CounterArt.product_display_texture(product_id)
		_assert(icon != null, "%s has a single-unit order bubble icon" % product_id)
		_assert(single != null, "%s has a single-unit drag texture" % product_id)
		_assert(display != null, "%s has a stacked storefront texture" % product_id)
		if StorefrontLayout.is_hanging_rail_product(product_id) and single != null and display != null:
			_assert(single.get_size().y < display.get_size().y, "%s keeps a smaller single packet separate from its stacked rail display" % product_id)
	var item := ProductDragItemScene.instantiate() as Control
	var product: ProductData = CampaignConfig.product_catalog[0]
	var single_texture := CounterArt.product_single_texture(product.id)
	item.call("configure", product, single_texture, true, StorefrontLayout.get_product_display_size(product.id), false, CounterArt.product_display_texture(product.id))
	root.add_child(item)
	await process_frame
	_assert(item.has_method("get_drag_preview_texture"), "shelf items expose their single-unit drag preview texture")
	if item.has_method("get_drag_preview_texture"):
		_assert(item.call("get_drag_preview_texture") == single_texture, "drag previews use the single-unit texture, not the stacked display")
	item.queue_free()

func _test_order_bubbles_use_single_unit_icons() -> void:
	var actor := CustomerActorScene.instantiate() as Control
	root.add_child(actor)
	await process_frame
	for product_id in EXPECTED_PRODUCTS:
		var customer := CustomerStateScript.new("jun", OrderStateScript.new({product_id: 1}), 25.0, 100.0)
		actor.call("set_customer", customer, {})
		var order_grid: GridContainer = actor.get("order_grid")
		var bubble_item: Control = order_grid.get_child(0)
		var rendered_icon: Texture2D = bubble_item.get_child(0).get("icon_texture")
		_assert(rendered_icon == CounterArt.product_icon(product_id, ProductAtlas), "%s renders its mapped single-unit icon in the order bubble" % product_id)
	actor.queue_free()

func _test_future_products_stay_locked_out_of_stock() -> void:
	var campaign := CampaignStateScript.new(CampaignConfig)
	for product_resource in CampaignConfig.product_catalog:
		var product: ProductData = product_resource
		if product.unlock_day > campaign.day:
			_assert(not campaign.is_product_available(product), "%s remains absent until its campaign day unlocks" % product.id)

func _assert(condition: bool, description: String) -> void:
	if condition:
		return
	failures += 1
	push_error("FAIL: " + description)
