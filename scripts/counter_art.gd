class_name CounterArt
extends RefCounted

## Product pixels are authored PNG assets declared by ProductData resources.
## This helper only routes assigned textures to storefront, drag, and order UI.
const CAMPAIGN := preload("res://data/story/summer_campaign.tres")

const DISPLAY_TINT := Color.WHITE
const DISPLAY_SHADOW_COLOR := Color(0.12, 0.07, 0.04, 0.22)

const CUSTOMER_REGIONS := {
	"tonyo": Rect2(0.0, 0.0, 512.0, 512.0),
	"tonyo_bored": Rect2(0.0, 0.0, 512.0, 512.0),
	"tonyo_flustered": Rect2(512.0, 0.0, 512.0, 512.0),
	"tonyo_determined": Rect2(1024.0, 0.0, 512.0, 512.0),
	"tonyo_smiling_tired": Rect2(1536.0, 0.0, 512.0, 512.0),
	"tonyo_counter": Rect2(2048.0, 0.0, 512.0, 512.0),
	"aling_cora": Rect2(2560.0, 0.0, 512.0, 512.0),
	"aling_cora_smiling": Rect2(3072.0, 0.0, 512.0, 512.0),
	"aling_cora_reading": Rect2(0.0, 512.0, 512.0, 512.0),
	"jun_jun": Rect2(512.0, 512.0, 512.0, 512.0),
	"jun_jun_tara": Rect2(1024.0, 512.0, 512.0, 512.0),
	"mikay": Rect2(1536.0, 512.0, 512.0, 512.0),
	"mikay_smug": Rect2(2048.0, 512.0, 512.0, 512.0),
	"bogs": Rect2(2560.0, 512.0, 512.0, 512.0),
	"bogs_small_smile": Rect2(3072.0, 512.0, 512.0, 512.0),
	"aling_nena": Rect2(0.0, 1024.0, 512.0, 512.0),
	"aling_nena_haggling": Rect2(512.0, 1024.0, 512.0, 512.0),
	"aling_nena_happy": Rect2(1024.0, 1024.0, 512.0, 512.0),
	"aling_nena_impatient": Rect2(1536.0, 1024.0, 512.0, 512.0),
	"aling_nena_embarrassed": Rect2(2048.0, 1024.0, 512.0, 512.0),
	"mang_berting": Rect2(2560.0, 1024.0, 512.0, 512.0),
	"mang_berting_happy": Rect2(3072.0, 1024.0, 512.0, 512.0),
	"mang_berting_impatient": Rect2(0.0, 1536.0, 512.0, 512.0),
	"bea": Rect2(512.0, 1536.0, 512.0, 512.0),
	"bea_happy": Rect2(1024.0, 1536.0, 512.0, 512.0),
	"bea_sad": Rect2(1536.0, 1536.0, 512.0, 512.0),
	"paolo": Rect2(2048.0, 1536.0, 512.0, 512.0),
	"paolo_happy": Rect2(2560.0, 1536.0, 512.0, 512.0),
	"paolo_sad": Rect2(3072.0, 1536.0, 512.0, 512.0),
	"kuya_dodong": Rect2(0.0, 2048.0, 512.0, 512.0),
	"kuya_dodong_thoughtful": Rect2(512.0, 2048.0, 512.0, 512.0),
	"kuya_dodong_soaked": Rect2(1024.0, 2048.0, 512.0, 512.0),
}

static func product_icon(product_id: String, _product_atlas: Texture2D = null) -> Texture2D:
	return product_single_texture(product_id)

static func product_single_texture(product_id: String) -> Texture2D:
	var product := _find_product(product_id)
	return product.single_unit_texture if product != null else null

static func product_display_texture(product_id: String) -> Texture2D:
	var product := _find_product(product_id)
	return product.stacked_texture if product != null else null

static func product_fixture_texture(product_id: String) -> Texture2D:
	return product_display_texture(product_id)

static func customer_portrait(customer_id: String, portrait_atlas: Texture2D) -> AtlasTexture:
	if portrait_atlas == null:
		return null
	var portrait := AtlasTexture.new()
	portrait.atlas = portrait_atlas
	portrait.region = CUSTOMER_REGIONS.get(customer_id, CUSTOMER_REGIONS["tonyo"])
	return portrait

static func fit_texture_rect(texture_size: Vector2, bounds: Vector2) -> Rect2:
	if texture_size.x <= 0.0 or texture_size.y <= 0.0 or bounds.x <= 0.0 or bounds.y <= 0.0:
		return Rect2()
	var fitted_size := texture_size * minf(bounds.x / texture_size.x, bounds.y / texture_size.y)
	return Rect2((bounds - fitted_size) * 0.5, fitted_size)

static func get_product_display_tint() -> Color:
	return DISPLAY_TINT

static func get_display_shadow_color() -> Color:
	return DISPLAY_SHADOW_COLOR

static func get_display_shadow_polygon(item_rect: Rect2) -> PackedVector2Array:
	var radius_x := maxf(1.0, item_rect.size.x * 0.39)
	var radius_y := maxf(0.75, item_rect.size.y * 0.035)
	var center := Vector2(item_rect.get_center().x, item_rect.end.y - radius_y * 0.25)
	var points := PackedVector2Array()
	for index in range(8):
		var angle := TAU * float(index) / 8.0
		points.append(center + Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	return points

static func _find_product(product_id: String) -> ProductData:
	for product_resource in CAMPAIGN.product_catalog:
		var product := product_resource as ProductData
		if product != null and product.id == product_id:
			return product
	push_error("Missing ProductData for product id: %s" % product_id)
	return null
