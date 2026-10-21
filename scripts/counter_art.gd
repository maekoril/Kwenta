class_name CounterArt
extends RefCounted

static var _display_cache: Dictionary = {}

const DISPLAY_TINT := Color(1.0, 0.96, 0.89, 1.0)
const DISPLAY_SHADOW_COLOR := Color(0.12, 0.07, 0.04, 0.22)

const PRODUCT_REGIONS := {
	"chips": Rect2(60.0, 55.0, 250.0, 285.0),
	"coffee_sachet": Rect2(440.0, 80.0, 230.0, 250.0),
	"shampoo_sachet": Rect2(800.0, 55.0, 210.0, 280.0),
	"toothpaste_sachet": Rect2(1110.0, 90.0, 315.0, 240.0),
	"laundry_sachet": Rect2(55.0, 390.0, 260.0, 315.0),
	"instant_noodles": Rect2(420.0, 425.0, 260.0, 280.0),
	"soft_drink": Rect2(830.0, 375.0, 165.0, 350.0),
	"biscuits": Rect2(1120.0, 450.0, 300.0, 260.0),
	"canned_sardines": Rect2(85.0, 740.0, 215.0, 290.0),
	"bottled_water": Rect2(455.0, 730.0, 165.0, 335.0),
	"candy": Rect2(770.0, 720.0, 265.0, 340.0),
}

const CUSTOMER_REGIONS := {
	"aleng_mila": Rect2(0.0, 0.0, 512.0, 512.0),
	"jun": Rect2(512.0, 0.0, 512.0, 512.0),
	"manong_tomas": Rect2(1024.0, 0.0, 512.0, 512.0),
	"ate_liza": Rect2(0.0, 512.0, 512.0, 512.0),
	"nina": Rect2(512.0, 512.0, 512.0, 512.0),
	"kuya_ben": Rect2(1024.0, 512.0, 512.0, 512.0),
}

const PRODUCT_ICON_PATHS := {
	"instant_noodles": "res://assets/sprites/products/redesign/icon/icon_nissin_cup_original_48x48.png",
	"soft_drink": "res://assets/sprites/products/redesign/icon/icon_coke_48x48.png",
	"chips": "res://assets/sprites/products/redesign/icon/icon_piattos_48x48.png",
	"biscuits": "res://assets/sprites/products/redesign/icon/icon_fita_48x48.png",
	"bottled_water": "res://assets/sprites/products/redesign/icon/icon_water_bottle_48x48.png",
	"candy": "res://assets/sprites/products/redesign/icon/icon_max_yellow_gum_48x48.png",
	"coffee_sachet": "res://assets/sprites/products/redesign/icon/icon_kopiko_blanca_48x48.png",
	"juice_sachet": "res://assets/sprites/products/redesign/icon/icon_tang_orange_48x48.png",
	"iced_tea_sachet": "res://assets/sprites/products/redesign/icon/icon_nestea_lemon_48x48.png",
	"canned_sardines": "res://assets/sprites/products/redesign/icon/icon_mega_sardines_48x48.png",
	"bread": "res://assets/sprites/products/redesign/icon/icon_gardenia_wheat_bread_48x48.png",
	"eggs": "res://assets/sprites/products/redesign/icon/icon_egg_48x48.png",
	"soy_sauce": "res://assets/sprites/products/redesign/icon/icon_datu_puti_soy_sauce_48x48.png",
	"vinegar": "res://assets/sprites/products/redesign/icon/icon_datu_puti_vinegar_48x48.png",
	"fish_sauce": "res://assets/sprites/products/redesign/icon/icon_datu_puti_fish_sauce_48x48.png",
	"cooking_oil": "res://assets/sprites/products/redesign/icon/icon_golden_fiesta_oil_48x48.png",
	"rice": "res://assets/sprites/products/redesign/icon/icon_princess_jasmine_rice_5kg_48x48.png",
}

const PRODUCT_SINGLE_PATHS := {
	"instant_noodles": "res://assets/sprites/products/redesign/single/single_nissin_cup_original_180x240.png",
	"soft_drink": "res://assets/sprites/products/redesign/single/single_coke_180x240.png",
	"chips": "res://assets/sprites/products/redesign/single/single_piattos_180x240.png",
	"biscuits": "res://assets/sprites/products/redesign/single/single_fita_180x240.png",
	"bottled_water": "res://assets/sprites/products/redesign/single/single_water_bottle_180x240.png",
	"candy": "res://assets/sprites/products/redesign/single/single_max_yellow_gum_180x240.png",
	"coffee_sachet": "res://assets/sprites/products/redesign/single/single_kopiko_blanca_180x240.png",
	"juice_sachet": "res://assets/sprites/products/redesign/single/single_tang_orange_180x240.png",
	"iced_tea_sachet": "res://assets/sprites/products/redesign/single/single_nestea_lemon_180x240.png",
	"canned_sardines": "res://assets/sprites/products/redesign/single/single_mega_sardines_180x240.png",
	"bread": "res://assets/sprites/products/redesign/single/single_gardenia_wheat_bread_180x240.png",
	"eggs": "res://assets/sprites/products/redesign/single/single_egg_180x240.png",
	"soy_sauce": "res://assets/sprites/products/redesign/single/single_datu_puti_soy_sauce_180x240.png",
	"vinegar": "res://assets/sprites/products/redesign/single/single_datu_puti_vinegar_180x240.png",
	"fish_sauce": "res://assets/sprites/products/redesign/single/single_datu_puti_fish_sauce_180x240.png",
	"cooking_oil": "res://assets/sprites/products/redesign/single/single_golden_fiesta_oil_180x240.png",
	"rice": "res://assets/sprites/products/redesign/single/single_princess_jasmine_rice_5kg_180x240.png",
}

const PRODUCT_DISPLAY_PATHS := {
	"instant_noodles": "res://assets/sprites/products/redesign/stack/stack_nissin_cup_display_redesign.png",
	"soft_drink": "res://assets/sprites/fixtures/cooler_coke_stocked.png",
	"chips": "res://assets/sprites/products/redesign/stack/stack_piattos_display_redesign.png",
	"biscuits": "res://assets/sprites/products/redesign/stack/stack_fita_display_redesign.png",
	"bottled_water": "res://assets/sprites/products/redesign/stack/stack_water_display_redesign.png",
	"candy": "res://assets/sprites/fixtures/candy_jar_stocked.png",
	"coffee_sachet": "res://assets/sprites/products/redesign/stack/stack_kopiko_blanca_sachet_redesign.png",
	"juice_sachet": "res://assets/sprites/products/redesign/stack/stack_tang_orange_sachet_redesign.png",
	"iced_tea_sachet": "res://assets/sprites/products/redesign/stack/stack_nestea_lemon_sachet_redesign.png",
	"shampoo_sachet": "res://assets/sprites/products/redesign/stack/stack_shampoo_sachet_redesign.png",
	"toothpaste_sachet": "res://assets/sprites/products/redesign/stack/stack_toothpaste_sachet_redesign.png",
	"laundry_sachet": "res://assets/sprites/products/redesign/stack/stack_laundry_sachet_redesign.png",
	"canned_sardines": "res://assets/sprites/products/redesign/stack/stack_mega_sardines_redesign.png",
	"bread": "res://assets/sprites/products/redesign/stack/stack_gardenia_wheat_bread_redesign.png",
	"eggs": "res://assets/sprites/products/redesign/stack/stack_egg_tray_redesign.png",
	"soy_sauce": "res://assets/sprites/products/redesign/stack/stack_datu_puti_soy_sauce_redesign.png",
	"vinegar": "res://assets/sprites/products/redesign/stack/stack_datu_puti_vinegar_redesign.png",
	"fish_sauce": "res://assets/sprites/products/redesign/stack/stack_datu_puti_fish_sauce_redesign.png",
	"cooking_oil": "res://assets/sprites/products/redesign/stack/stack_golden_fiesta_oil_redesign.png",
	"rice": "res://assets/sprites/products/redesign/stack/stack_jasmine_rice_redesign.png",
}

const PRODUCT_FIXTURE_PATHS := {
	"candy": "res://assets/sprites/fixtures/candy_jar_stocked.png",
	"soft_drink": "res://assets/sprites/fixtures/cooler_coke_stocked.png",
}

static func product_icon(product_id: String, product_atlas: Texture2D) -> Texture2D:
	var branded_icon := _load_product_texture(PRODUCT_ICON_PATHS, product_id)
	if branded_icon != null:
		return branded_icon
	var region: Rect2 = PRODUCT_REGIONS.get(product_id, Rect2())
	if product_atlas == null or region.size == Vector2.ZERO:
		return null
	var icon := AtlasTexture.new()
	icon.atlas = product_atlas
	icon.region = region
	return icon

static func product_single_texture(product_id: String) -> Texture2D:
	return _load_product_texture(PRODUCT_SINGLE_PATHS, product_id)

static func product_display_texture(product_id: String) -> Texture2D:
	if _display_cache.has(product_id):
		return _display_cache[product_id]
	if PRODUCT_FIXTURE_PATHS.has(product_id):
		var combined_fixture := product_fixture_texture(product_id)
		if combined_fixture != null:
			_display_cache[product_id] = combined_fixture
			return combined_fixture
	var display_texture := _load_product_texture(PRODUCT_DISPLAY_PATHS, product_id)
	if display_texture != null:
		var used_region: Rect2 = Rect2(display_texture.get_image().get_used_rect())
		if used_region.size != Vector2.ZERO:
			var trimmed := AtlasTexture.new()
			trimmed.atlas = display_texture
			trimmed.region = used_region
			_display_cache[product_id] = trimmed
			return trimmed
		return display_texture
	return product_single_texture(product_id)

static func product_fixture_texture(product_id: String) -> Texture2D:
	return _load_product_texture(PRODUCT_FIXTURE_PATHS, product_id)

static func _load_product_texture(texture_paths: Dictionary, product_id: String) -> Texture2D:
	var path := str(texture_paths.get(product_id, ""))
	if path.is_empty():
		return null
	return load(path) as Texture2D

static func customer_portrait(customer_id: String, portrait_atlas: Texture2D) -> AtlasTexture:
	var region: Rect2 = CUSTOMER_REGIONS.get(customer_id, Rect2(0.0, 0.0, 512.0, 512.0))
	if portrait_atlas == null:
		return null
	var portrait := AtlasTexture.new()
	portrait.atlas = portrait_atlas
	portrait.region = region
	return portrait

static func fit_texture_rect(texture_size: Vector2, bounds: Vector2) -> Rect2:
	if texture_size.x <= 0.0 or texture_size.y <= 0.0 or bounds.x <= 0.0 or bounds.y <= 0.0:
		return Rect2()
	var fit_scale: float = minf(bounds.x / texture_size.x, bounds.y / texture_size.y)
	var fitted_size: Vector2 = texture_size * fit_scale
	fitted_size.x = minf(fitted_size.x, bounds.x)
	fitted_size.y = minf(fitted_size.y, bounds.y)
	return Rect2((bounds - fitted_size) * 0.5, fitted_size)

static func get_product_display_tint() -> Color:
	return DISPLAY_TINT

static func get_display_shadow_color() -> Color:
	return DISPLAY_SHADOW_COLOR

static func get_display_shadow_polygon(item_rect: Rect2) -> PackedVector2Array:
	var radius_x: float = maxf(1.0, item_rect.size.x * 0.39)
	var radius_y: float = maxf(0.75, item_rect.size.y * 0.035)
	var center := Vector2(item_rect.get_center().x, item_rect.end.y - radius_y * 0.25)
	var points := PackedVector2Array()
	for index in range(8):
		var angle: float = TAU * float(index) / 8.0
		points.append(center + Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	return points
