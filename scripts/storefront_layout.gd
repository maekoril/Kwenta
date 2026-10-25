class_name StorefrontLayout
extends RefCounted

# All coordinates are in 1920x1080 viewport space (the old 640x360 values x3).
const VIEWPORT_SIZE := Vector2(1920.0, 1080.0)
const WINDOW_RECT := Rect2(450.0, 72.0, 1020.0, 528.0)
const CUSTOMER_WIDTH: float = 240.0
const CUSTOMER_Y: float = 84.0
const CUSTOMER_HEIGHT: float = 600.0
const MAX_CUSTOMERS: int = 5
const MAX_ACTIVE_WINDOW_CUSTOMERS: int = 2
const CUSTOMER_SPAWN_DELAY_MIN_SECONDS: float = 5.0
const CUSTOMER_SPAWN_DELAY_MAX_SECONDS: float = 12.0
const CUSTOMER_PATIENCE_SECONDS: float = 25.0
const CONTACT_SHADOW_HEIGHT: float = 4.5

# Named, viewport-space areas let the scene tree and product slots share the
# same 1920x1080 reference coordinates without turning the background art into
# an input surface.
const STOREFRONT_ZONES := {
	"customer_window": WINDOW_RECT,
	"top_left_rail": Rect2(75.0, 63.0, 270.0, 180.0),
	"top_right_rail": Rect2(1575.0, 63.0, 215.0, 180.0),
	"countertop": Rect2(126.0, 513.0, 314.0, 72.0),
	"shelf_row_a": Rect2(126.0, 600.0, 1658.0, 156.0),
	"shelf_row_b": Rect2(148.0, 770.0, 1608.0, 214.0),
}

# Touch areas follow the shelf bays, jar, cooler and hanging rails in the
# clean interior artwork. Composite display sprites draw once per slot.
const PRODUCT_SLOT_RECTS := {
	# Upper shelf, bays 1-3 (floor line y=756; bay 4 left empty for unlocks)
	"sandwich_biscuits": Rect2(150.0, 651.0, 124.0, 105.0),
	"instant_noodles": Rect2(282.0, 651.0, 130.0, 105.0),
	"noodle_pack": Rect2(420.0, 651.0, 130.0, 105.0),
	"biscuits": Rect2(610.0, 651.0, 127.0, 105.0),
	"canned_sardines": Rect2(745.0, 651.0, 127.0, 105.0),
	"bubble_gum": Rect2(880.0, 681.0, 84.0, 75.0),
	"candy": Rect2(1144.0, 681.0, 132.0, 75.0),
	# Lower shelf, bays 1-3 (floor line y=984)
	"soy_sauce": Rect2(232.0, 879.0, 80.0, 105.0),
	"vinegar": Rect2(327.0, 879.0, 80.0, 105.0),
	"fish_sauce": Rect2(422.0, 879.0, 80.0, 105.0),
	"bottled_water": Rect2(620.0, 876.0, 124.0, 108.0),
	"soft_drink": Rect2(770.0, 858.0, 264.0, 126.0),
	"cooking_oil": Rect2(1200.0, 867.0, 110.0, 117.0),
	"rice": Rect2(1420.0, 792.0, 264.0, 192.0),
	# Counter, left of the service window (base line y=585)
	"bread": Rect2(140.0, 513.0, 126.0, 72.0),
	"eggs": Rect2(280.0, 513.0, 114.0, 72.0),
	# Hanging rails, one sachet per hook
	"coffee_sachet": Rect2(85.0, 63.0, 60.0, 180.0),
	"juice_sachet": Rect2(147.0, 63.0, 60.0, 180.0),
	"iced_tea_sachet": Rect2(209.0, 63.0, 60.0, 180.0),
	"chips": Rect2(271.0, 63.0, 60.0, 180.0),
	"toothpaste_sachet": Rect2(1587.0, 63.0, 60.0, 180.0),
	"shampoo_sachet": Rect2(1650.0, 63.0, 60.0, 180.0),
	"laundry_sachet": Rect2(1717.0, 63.0, 60.0, 180.0),
}

const PRODUCT_DISPLAY_SIZES := {
	"instant_noodles": Vector2(114.0, 105.0),
	"sandwich_biscuits": Vector2(108.0, 105.0),
	"noodle_pack": Vector2(114.0, 105.0),
	"bubble_gum": Vector2(72.0, 66.0),
	"chips": Vector2(60.0, 168.0),
	"biscuits": Vector2(111.0, 105.0),
	"canned_sardines": Vector2(111.0, 105.0),
	"coffee_sachet": Vector2(60.0, 168.0),
	"juice_sachet": Vector2(60.0, 168.0),
	"iced_tea_sachet": Vector2(60.0, 168.0),
	"toothpaste_sachet": Vector2(60.0, 168.0),
	"shampoo_sachet": Vector2(60.0, 168.0),
	"laundry_sachet": Vector2(60.0, 168.0),
	"candy": Vector2(102.0, 66.0),
	"soft_drink": Vector2(81.0, 72.0),
	"bottled_water": Vector2(108.0, 108.0),
	"bread": Vector2(108.0, 72.0),
	"eggs": Vector2(96.0, 72.0),
	"soy_sauce": Vector2(66.0, 105.0),
	"vinegar": Vector2(66.0, 105.0),
	"fish_sauce": Vector2(66.0, 105.0),
	"cooking_oil": Vector2(96.0, 117.0),
	"rice": Vector2(138.0, 138.0),
}

const STOCK_COUNTS := {
	"soft_drink": 3,
}

const PRODUCT_LAYOUT_ZONES := {
	"coffee_sachet": "top_left_rail", "juice_sachet": "top_left_rail", "iced_tea_sachet": "top_left_rail", "chips": "top_left_rail",
	"toothpaste_sachet": "top_right_rail", "shampoo_sachet": "top_right_rail", "laundry_sachet": "top_right_rail",
	"bread": "countertop", "eggs": "countertop",
	"instant_noodles": "shelf_row_a", "sandwich_biscuits": "shelf_row_a", "noodle_pack": "shelf_row_a", "bubble_gum": "shelf_row_a", "biscuits": "shelf_row_a", "canned_sardines": "shelf_row_a", "candy": "shelf_row_a",
	"soft_drink": "shelf_row_b", "bottled_water": "shelf_row_b", "soy_sauce": "shelf_row_b", "vinegar": "shelf_row_b", "fish_sauce": "shelf_row_b", "cooking_oil": "shelf_row_b", "rice": "shelf_row_b",
}

const HANGING_RAIL_PRODUCT_IDS := ["coffee_sachet", "juice_sachet", "iced_tea_sachet", "chips", "toothpaste_sachet", "shampoo_sachet", "laundry_sachet"]

static func get_product_slot(product_id: String) -> Rect2:
	return PRODUCT_SLOT_RECTS.get(product_id, Rect2())

static func get_storefront_zone(zone_id: String) -> Rect2:
	return STOREFRONT_ZONES.get(zone_id, Rect2())

static func get_product_layout_zone(product_id: String) -> String:
	return str(PRODUCT_LAYOUT_ZONES.get(product_id, ""))

static func is_hanging_rail_product(product_id: String) -> bool:
	return HANGING_RAIL_PRODUCT_IDS.has(product_id)

static func get_customer_drop_rect(customer_x: float) -> Rect2:
	return Rect2(customer_x, CUSTOMER_Y, CUSTOMER_WIDTH, CUSTOMER_HEIGHT)

static func get_product_contact_shadow_rect(product_id: String) -> Rect2:
	var slot: Rect2 = get_product_slot(product_id)
	if slot.size == Vector2.ZERO:
		return Rect2()
	return Rect2(slot.position.x + 3.0, slot.end.y - CONTACT_SHADOW_HEIGHT, maxf(0.0, slot.size.x - 6.0), CONTACT_SHADOW_HEIGHT)

static func get_product_display_size(product_id: String) -> Vector2:
	return PRODUCT_DISPLAY_SIZES.get(product_id, Vector2.ZERO)

static func get_stock_count(product_id: String) -> int:
	return STOCK_COUNTS.get(product_id, 1)

static func is_product_rotated(product_id: String) -> bool:
	return false

static func get_customer_x_positions(count: int) -> Array[float]:
	var positions: Array[float] = []
	var customer_count: int = mini(count, MAX_CUSTOMERS)
	var gap: float = (WINDOW_RECT.size.x - float(customer_count) * CUSTOMER_WIDTH) / float(customer_count + 1)
	for index in range(customer_count):
		positions.append(WINDOW_RECT.position.x + gap * float(index + 1) + CUSTOMER_WIDTH * float(index))
	return positions

static func get_order_icon_entries(requested: Dictionary, delivered: Dictionary) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for product_id in requested:
		var remaining: int = maxi(0, int(requested[product_id]) - int(delivered.get(product_id, 0)))
		entries.append({
			"product_id": str(product_id),
			"requested": int(requested[product_id]),
			"remaining": remaining,
			"completed": remaining == 0,
		})
	return entries
