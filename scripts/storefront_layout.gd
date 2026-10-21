class_name StorefrontLayout
extends RefCounted

const VIEWPORT_SIZE := Vector2(640.0, 360.0)
const WINDOW_RECT := Rect2(150.0, 24.0, 340.0, 176.0)
const CUSTOMER_WIDTH: float = 68.0
const CUSTOMER_Y: float = 47.0
const CUSTOMER_HEIGHT: float = 146.0
const MAX_CUSTOMERS: int = 5

# Touch areas follow the shelf bays, jar, cooler and hanging rails in the
# clean interior artwork. Stock repeats within a bay but shares one drag area.
const PRODUCT_SLOT_RECTS := {
	"instant_noodles": Rect2(42.0, 207.0, 58.0, 49.0),
	"chips": Rect2(103.0, 207.0, 74.0, 49.0),
	"biscuits": Rect2(190.0, 207.0, 130.0, 49.0),
	"canned_sardines": Rect2(332.0, 207.0, 135.0, 49.0),
	"coffee_sachet": Rect2(34.0, 26.0, 28.0, 62.0),
	"juice_sachet": Rect2(66.0, 26.0, 28.0, 62.0),
	"iced_tea_sachet": Rect2(98.0, 26.0, 28.0, 62.0),
	"toothpaste_sachet": Rect2(503.0, 26.0, 28.0, 62.0),
	"shampoo_sachet": Rect2(535.0, 26.0, 28.0, 62.0),
	"laundry_sachet": Rect2(567.0, 26.0, 28.0, 62.0),
	"candy": Rect2(484.0, 195.0, 86.0, 65.0),
	"soft_drink": Rect2(0.0, 260.0, 195.0, 100.0),
	"bottled_water": Rect2(203.0, 282.0, 170.0, 57.0),
	"bread": Rect2(176.0, 254.0, 74.0, 45.0),
	"eggs": Rect2(252.0, 254.0, 74.0, 45.0),
	"soy_sauce": Rect2(328.0, 254.0, 52.0, 45.0),
	"vinegar": Rect2(382.0, 254.0, 52.0, 45.0),
	"fish_sauce": Rect2(436.0, 254.0, 52.0, 45.0),
	"cooking_oil": Rect2(470.0, 264.0, 74.0, 54.0),
	"rice": Rect2(378.0, 300.0, 88.0, 56.0),
}

const PRODUCT_DISPLAY_SIZES := {
	"instant_noodles": Vector2(38.0, 35.0),
	"chips": Vector2(38.0, 35.0),
	"biscuits": Vector2(37.0, 35.0),
	"canned_sardines": Vector2(37.0, 35.0),
	"coffee_sachet": Vector2(20.0, 42.0),
	"juice_sachet": Vector2(20.0, 42.0),
	"iced_tea_sachet": Vector2(20.0, 42.0),
	"toothpaste_sachet": Vector2(20.0, 42.0),
	"shampoo_sachet": Vector2(20.0, 42.0),
	"laundry_sachet": Vector2(20.0, 42.0),
	"candy": Vector2(34.0, 22.0),
	"soft_drink": Vector2(27.0, 24.0),
	"bottled_water": Vector2(36.0, 36.0),
	"bread": Vector2(38.0, 35.0),
	"eggs": Vector2(34.0, 35.0),
	"soy_sauce": Vector2(22.0, 35.0),
	"vinegar": Vector2(22.0, 35.0),
	"fish_sauce": Vector2(22.0, 35.0),
	"cooking_oil": Vector2(32.0, 39.0),
	"rice": Vector2(46.0, 46.0),
}

const STOCK_COUNTS := {
	"biscuits": 3,
	"canned_sardines": 3,
	"bottled_water": 3,
}

static func get_product_slot(product_id: String) -> Rect2:
	return PRODUCT_SLOT_RECTS.get(product_id, Rect2())

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
