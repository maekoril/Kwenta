class_name StorefrontLayout
extends RefCounted

const VIEWPORT_SIZE := Vector2(640.0, 360.0)
const WINDOW_RECT := Rect2(150.0, 24.0, 340.0, 176.0)
const CUSTOMER_WIDTH: float = 68.0
const CUSTOMER_Y: float = 31.0
const CUSTOMER_HEIGHT: float = 175.0
const MAX_CUSTOMERS: int = 5
const MAX_ACTIVE_WINDOW_CUSTOMERS: int = 2
const CUSTOMER_SPAWN_DELAY_MIN_SECONDS: float = 5.0
const CUSTOMER_SPAWN_DELAY_MAX_SECONDS: float = 12.0
const CUSTOMER_PATIENCE_SECONDS: float = 25.0
const CONTACT_SHADOW_HEIGHT: float = 1.5

# Named, viewport-space areas let the scene tree and product slots share the
# same 640x360 reference coordinates without turning the background art into
# an input surface.
const STOREFRONT_ZONES := {
	"customer_window": WINDOW_RECT,
	"top_left_rail": Rect2(20.0, 24.0, 120.0, 60.0),
	"top_right_rail": Rect2(500.0, 24.0, 120.0, 60.0),
	"countertop": Rect2(20.0, 198.0, 600.0, 24.0),
	"shelf_row_a": Rect2(20.0, 224.0, 600.0, 61.0),
	"shelf_row_b": Rect2(20.0, 288.0, 600.0, 64.0),
}

# Touch areas follow the shelf bays, jar, cooler and hanging rails in the
# clean interior artwork. Composite display sprites draw once per slot.
const PRODUCT_SLOT_RECTS := {
	"instant_noodles": Rect2(185.0, 233.0, 52.0, 35.0),
	"sandwich_biscuits": Rect2(20.0, 224.0, 60.0, 61.0),
	"noodle_pack": Rect2(90.0, 233.0, 50.0, 35.0),
	"bubble_gum": Rect2(145.0, 240.0, 28.0, 25.0),
	"biscuits": Rect2(238.0, 233.0, 70.0, 35.0),
	"canned_sardines": Rect2(332.0, 224.0, 128.0, 61.0),
	"coffee_sachet": Rect2(20.0, 24.0, 28.0, 60.0),
	"juice_sachet": Rect2(50.0, 24.0, 28.0, 60.0),
	"iced_tea_sachet": Rect2(80.0, 24.0, 28.0, 60.0),
	"chips": Rect2(110.0, 24.0, 28.0, 60.0),
	"toothpaste_sachet": Rect2(508.0, 24.0, 28.0, 60.0),
	"shampoo_sachet": Rect2(548.0, 24.0, 28.0, 60.0),
	"laundry_sachet": Rect2(588.0, 24.0, 28.0, 60.0),
	"candy": Rect2(462.0, 240.0, 44.0, 25.0),
	"bread": Rect2(176.0, 198.0, 74.0, 24.0),
	"eggs": Rect2(254.0, 198.0, 74.0, 24.0),
	"soft_drink": Rect2(80.0, 288.0, 88.0, 42.0),
	"bottled_water": Rect2(280.0, 292.0, 72.0, 36.0),
	"soy_sauce": Rect2(190.0, 293.0, 26.0, 35.0),
	"vinegar": Rect2(218.0, 293.0, 26.0, 35.0),
	"fish_sauce": Rect2(246.0, 293.0, 26.0, 35.0),
	"cooking_oil": Rect2(370.0, 289.0, 32.0, 39.0),
	"rice": Rect2(476.0, 288.0, 88.0, 64.0),
}

const PRODUCT_DISPLAY_SIZES := {
	"instant_noodles": Vector2(38.0, 35.0),
	"sandwich_biscuits": Vector2(36.0, 35.0),
	"noodle_pack": Vector2(38.0, 35.0),
	"bubble_gum": Vector2(24.0, 22.0),
	"chips": Vector2(20.0, 56.0),
	"biscuits": Vector2(37.0, 35.0),
	"canned_sardines": Vector2(37.0, 35.0),
	"coffee_sachet": Vector2(20.0, 56.0),
	"juice_sachet": Vector2(20.0, 56.0),
	"iced_tea_sachet": Vector2(20.0, 56.0),
	"toothpaste_sachet": Vector2(20.0, 56.0),
	"shampoo_sachet": Vector2(20.0, 56.0),
	"laundry_sachet": Vector2(20.0, 56.0),
	"candy": Vector2(34.0, 22.0),
	"soft_drink": Vector2(27.0, 24.0),
	"bottled_water": Vector2(36.0, 36.0),
	"bread": Vector2(36.0, 24.0),
	"eggs": Vector2(32.0, 24.0),
	"soy_sauce": Vector2(22.0, 35.0),
	"vinegar": Vector2(22.0, 35.0),
	"fish_sauce": Vector2(22.0, 35.0),
	"cooking_oil": Vector2(32.0, 39.0),
	"rice": Vector2(46.0, 46.0),
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
	return Rect2(slot.position.x + 1.0, slot.end.y - CONTACT_SHADOW_HEIGHT, maxf(0.0, slot.size.x - 2.0), CONTACT_SHADOW_HEIGHT)

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
