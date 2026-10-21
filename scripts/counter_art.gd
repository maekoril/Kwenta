class_name CounterArt
extends RefCounted

static var _display_cache: Dictionary = {}
static var _single_cache: Dictionary = {}

const DISPLAY_TINT := Color.WHITE
const DISPLAY_SHADOW_COLOR := Color(0.12, 0.07, 0.04, 0.22)

# Each catalog product owns a palette, silhouette, and semantic pixel mark.
# The storefront never falls back to the old generic product atlas.
const PRODUCT_VISUAL_RECIPES := {
	"juice_sachet": {"primary": Color("f47d20"), "accent": Color("ffe05a"), "kind": "sachet", "stack": "strip", "mark": "citrus"},
	"iced_tea_sachet": {"primary": Color("c4dc45"), "accent": Color("3d8b4f"), "kind": "sachet", "stack": "strip", "mark": "leaf"},
	"coffee_sachet": {"primary": Color("f6edd8"), "accent": Color("5a3827"), "kind": "sachet", "stack": "strip", "mark": "bean"},
	"shampoo_sachet": {"primary": Color("087fba"), "accent": Color("63dbe3"), "kind": "sachet", "stack": "strip", "mark": "drop"},
	"toothpaste_sachet": {"primary": Color("dd463e"), "accent": Color("fff8eb"), "kind": "sachet", "stack": "strip", "mark": "tube"},
	"laundry_sachet": {"primary": Color("52ae67"), "accent": Color("f5fff3"), "kind": "sachet", "stack": "strip", "mark": "spark"},
	"chips": {"primary": Color("da4435"), "accent": Color("ffd34f"), "kind": "chip", "stack": "strip", "mark": "hex"},
	"biscuits": {"primary": Color("ce3e38"), "accent": Color("fff0d0"), "kind": "packet", "stack": "tray", "mark": "cracker"},
	"sandwich_biscuits": {"primary": Color("3b2a25"), "accent": Color("f2c94c"), "kind": "packet", "stack": "tray", "mark": "chocolate"},
	"bread": {"primary": Color("c9903e"), "accent": Color("73a958"), "kind": "bread", "stack": "bread", "mark": "loaf"},
	"instant_noodles": {"primary": Color("d6483d"), "accent": Color("fff7e8"), "kind": "cup", "stack": "tray", "mark": "cup"},
	"noodle_pack": {"primary": Color("f0b42d"), "accent": Color("e46d27"), "kind": "packet", "stack": "tray", "mark": "pancit"},
	"canned_sardines": {"primary": Color("cd4a37"), "accent": Color("54915d"), "kind": "can", "stack": "cans", "mark": "sardine"},
	"candy": {"primary": Color("9bd9e8"), "accent": Color("f0a63b"), "kind": "jar", "stack": "jar", "mark": "candy"},
	"bubble_gum": {"primary": Color("4d9c5b"), "accent": Color("a9df67"), "kind": "gum", "stack": "tray", "mark": "gum"},
	"eggs": {"primary": Color("b88a55"), "accent": Color("f0d4a1"), "kind": "egg", "stack": "egg_tray", "mark": "egg"},
	"soft_drink": {"primary": Color("d8423a"), "accent": Color("332626"), "kind": "bottle", "stack": "cooler", "mark": "cola"},
	"bottled_water": {"primary": Color("8acded"), "accent": Color("eafcff"), "kind": "bottle", "stack": "water_crate", "mark": "water"},
	"cooking_oil": {"primary": Color("5f9e59"), "accent": Color("f0c341"), "kind": "oil", "stack": "oil_crate", "mark": "oil"},
	"soy_sauce": {"primary": Color("55352a"), "accent": Color("edca4f"), "kind": "sauce", "stack": "rack", "mark": "soy"},
	"vinegar": {"primary": Color("e8efef"), "accent": Color("4f9b63"), "kind": "sauce", "stack": "rack", "mark": "vinegar"},
	"fish_sauce": {"primary": Color("a85e31"), "accent": Color("f0c27a"), "kind": "sauce", "stack": "rack", "mark": "fish"},
	"rice": {"primary": Color("b99a63"), "accent": Color("365f42"), "kind": "rice", "stack": "sack", "mark": "rice"},
}

const CUSTOMER_REGIONS := {
	"aleng_mila": Rect2(0.0, 0.0, 512.0, 512.0), "jun": Rect2(512.0, 0.0, 512.0, 512.0),
	"manong_tomas": Rect2(1024.0, 0.0, 512.0, 512.0), "ate_liza": Rect2(0.0, 512.0, 512.0, 512.0),
	"nina": Rect2(512.0, 512.0, 512.0, 512.0), "kuya_ben": Rect2(1024.0, 512.0, 512.0, 512.0),
}

func get_product_visual_recipe(product_id: String) -> Dictionary:
	return PRODUCT_VISUAL_RECIPES.get(product_id, {})

static func product_icon(product_id: String, _product_atlas: Texture2D = null) -> Texture2D:
	return product_single_texture(product_id)

static func product_single_texture(product_id: String) -> Texture2D:
	if _single_cache.has(product_id):
		return _single_cache[product_id]
	var texture := ImageTexture.create_from_image(_make_single_image(product_id))
	_single_cache[product_id] = texture
	return texture

static func product_display_texture(product_id: String) -> Texture2D:
	if _display_cache.has(product_id):
		return _display_cache[product_id]
	var texture := ImageTexture.create_from_image(_make_stacked_image(product_id))
	_display_cache[product_id] = texture
	return texture

static func product_fixture_texture(product_id: String) -> Texture2D:
	return product_display_texture(product_id)

static func customer_portrait(customer_id: String, portrait_atlas: Texture2D) -> AtlasTexture:
	if portrait_atlas == null:
		return null
	var portrait := AtlasTexture.new()
	portrait.atlas = portrait_atlas
	portrait.region = CUSTOMER_REGIONS.get(customer_id, Rect2(0.0, 0.0, 512.0, 512.0))
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

static func _make_single_image(product_id: String) -> Image:
	var image := Image.create(24, 24, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	var recipe: Dictionary = PRODUCT_VISUAL_RECIPES.get(product_id, _fallback_recipe(product_id))
	var primary: Color = recipe.primary
	var accent: Color = recipe.accent
	var outline := primary.darkened(0.48)
	match str(recipe.kind):
		"bread":
			_box(image, Rect2i(4, 10, 16, 10), outline)
			_box(image, Rect2i(5, 8, 14, 11), primary)
			_box(image, Rect2i(7, 6, 10, 5), primary)
			_box(image, Rect2i(3, 15, 18, 3), accent)
		"cup":
			_box(image, Rect2i(5, 5, 14, 3), outline)
			_box(image, Rect2i(6, 7, 12, 13), primary)
			_box(image, Rect2i(7, 5, 10, 2), accent)
			_box(image, Rect2i(7, 11, 10, 3), accent)
		"can":
			_box(image, Rect2i(7, 4, 10, 16), outline)
			_box(image, Rect2i(8, 5, 8, 14), primary)
			_box(image, Rect2i(8, 9, 8, 5), accent)
		"jar":
			_box(image, Rect2i(7, 3, 10, 3), Color("3b7fc2"))
			_box(image, Rect2i(6, 6, 12, 14), outline)
			_box(image, Rect2i(7, 7, 10, 12), primary.lightened(0.25))
			for candy_pos in [Vector2i(9, 11), Vector2i(13, 10), Vector2i(11, 15), Vector2i(15, 15)]:
				_box(image, Rect2i(candy_pos, Vector2i(2, 2)), accent)
		"gum":
			_box(image, Rect2i(2, 8, 20, 9), outline)
			_box(image, Rect2i(3, 9, 18, 7), primary)
			_box(image, Rect2i(5, 11, 14, 2), accent)
		"egg":
			for egg_pos in [Vector2i(5, 7), Vector2i(11, 5), Vector2i(16, 8)]:
				_box(image, Rect2i(egg_pos, Vector2i(4, 8)), primary)
				_box(image, Rect2i(egg_pos + Vector2i(1, 1), Vector2i(2, 5)), accent)
		"bottle", "oil", "sauce":
			_draw_bottle(image, recipe, Vector2i(7, 3), Vector2i(10, 18))
		"rice":
			_box(image, Rect2i(5, 6, 14, 15), outline)
			_box(image, Rect2i(6, 7, 12, 13), primary)
			_box(image, Rect2i(8, 11, 8, 5), accent)
		_:
			_draw_packet(image, recipe, Rect2i(5, 2, 14, 20))
	_draw_mark(image, recipe, Rect2i(8, 9, 8, 7))
	return image

static func _make_stacked_image(product_id: String) -> Image:
	var image := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	var recipe: Dictionary = PRODUCT_VISUAL_RECIPES.get(product_id, _fallback_recipe(product_id))
	var primary: Color = recipe.primary
	var accent: Color = recipe.accent
	var outline := primary.darkened(0.52)
	match str(recipe.stack):
		"strip":
			_box(image, Rect2i(22, 1, 4, 46), outline)
			for y in [3, 14, 25, 36]:
				_draw_packet(image, recipe, Rect2i(15, y, 18, 10))
		"cooler", "water_crate", "oil_crate":
			_box(image, Rect2i(2, 27, 44, 18), outline)
			_box(image, Rect2i(4, 29, 40, 14), primary)
			_box(image, Rect2i(6, 32, 36, 2), accent)
			for x in [9, 20, 31]:
				_draw_bottle(image, recipe, Vector2i(x, 10), Vector2i(8, 19))
		"rack":
			_box(image, Rect2i(3, 16, 42, 4), Color("71482d"))
			_box(image, Rect2i(3, 38, 42, 4), Color("71482d"))
			for x in [9, 20, 31]:
				_draw_bottle(image, recipe, Vector2i(x, 18), Vector2i(8, 20))
		"sack":
			_box(image, Rect2i(10, 8, 28, 35), outline)
			_box(image, Rect2i(12, 10, 24, 31), primary)
			_box(image, Rect2i(15, 21, 18, 8), accent)
		"jar":
			_box(image, Rect2i(12, 4, 24, 6), Color("3b7fc2"))
			_box(image, Rect2i(9, 10, 30, 33), outline)
			_box(image, Rect2i(11, 12, 26, 29), primary.lightened(0.24))
			for candy_pos in [Vector2i(15, 20), Vector2i(23, 17), Vector2i(30, 22), Vector2i(19, 31), Vector2i(28, 32)]:
				_box(image, Rect2i(candy_pos, Vector2i(5, 5)), accent)
		"egg_tray":
			_box(image, Rect2i(3, 29, 42, 13), outline)
			_box(image, Rect2i(5, 31, 38, 9), primary)
			for egg_pos in [Vector2i(9, 17), Vector2i(20, 14), Vector2i(31, 18)]:
				_box(image, Rect2i(egg_pos, Vector2i(8, 14)), accent)
		"cans":
			for x in [6, 19, 32]:
				_box(image, Rect2i(x, 18, 11, 21), outline)
				_box(image, Rect2i(x + 1, 19, 9, 19), primary)
				_box(image, Rect2i(x + 1, 25, 9, 5), accent)
		_:
			_box(image, Rect2i(2, 37, 44, 7), outline)
			for x in [4, 17, 30]:
				_draw_packet(image, recipe, Rect2i(x, 12, 14, 25))
	return image

static func _draw_packet(image: Image, recipe: Dictionary, bounds: Rect2i) -> void:
	var primary: Color = recipe.primary
	var accent: Color = recipe.accent
	_box(image, bounds, primary.darkened(0.48))
	_box(image, Rect2i(bounds.position + Vector2i(1, 1), bounds.size - Vector2i(2, 2)), primary)
	_box(image, Rect2i(bounds.position + Vector2i(2, bounds.size.y / 2 - 1), Vector2i(bounds.size.x - 4, 3)), accent)
	_draw_mark(image, recipe, Rect2i(bounds.position + Vector2i(bounds.size.x / 2 - 3, bounds.size.y / 2 - 4), Vector2i(6, 6)))

static func _draw_bottle(image: Image, recipe: Dictionary, position: Vector2i, bottle_size: Vector2i) -> void:
	var primary: Color = recipe.primary
	var accent: Color = recipe.accent
	_box(image, Rect2i(position.x + bottle_size.x / 2 - 2, position.y, 4, 4), primary.darkened(0.5))
	_box(image, Rect2i(position.x + 1, position.y + 4, bottle_size.x - 2, bottle_size.y - 4), primary.darkened(0.5))
	_box(image, Rect2i(position.x + 2, position.y + 5, bottle_size.x - 4, bottle_size.y - 6), primary)
	_box(image, Rect2i(position.x + 2, position.y + bottle_size.y / 2, bottle_size.x - 4, 4), accent)

static func _draw_mark(image: Image, recipe: Dictionary, bounds: Rect2i) -> void:
	var accent: Color = recipe.accent
	var dark: Color = accent.darkened(0.45)
	match str(recipe.mark):
		"citrus":
			_box(image, Rect2i(bounds.position + Vector2i(1, 1), Vector2i(6, 5)), accent)
			_box(image, Rect2i(bounds.position + Vector2i(3, 1), Vector2i(1, 5)), dark)
		"leaf":
			for offset in range(5):
				_box(image, Rect2i(bounds.position + Vector2i(offset, 4 - offset / 2), Vector2i(2, 2)), accent)
		"bean":
			_box(image, Rect2i(bounds.position + Vector2i(2, 1), Vector2i(4, 6)), dark)
			_box(image, Rect2i(bounds.position + Vector2i(3, 1), Vector2i(1, 6)), accent)
		"drop":
			_box(image, Rect2i(bounds.position + Vector2i(3, 1), Vector2i(2, 2)), accent)
			_box(image, Rect2i(bounds.position + Vector2i(2, 3), Vector2i(4, 4)), accent)
		"tube":
			_box(image, Rect2i(bounds.position + Vector2i(0, 2), Vector2i(8, 3)), accent)
		"spark":
			_box(image, Rect2i(bounds.position + Vector2i(3, 0), Vector2i(2, 8)), accent)
			_box(image, Rect2i(bounds.position + Vector2i(0, 3), Vector2i(8, 2)), accent)
		"hex":
			_box(image, Rect2i(bounds.position + Vector2i(2, 0), Vector2i(4, 8)), accent)
			_box(image, Rect2i(bounds.position + Vector2i(0, 2), Vector2i(8, 4)), accent)
		_:
			_box(image, Rect2i(bounds.position + Vector2i(1, 2), Vector2i(maxi(2, bounds.size.x - 2), 3)), accent)

static func _box(image: Image, rect: Rect2i, color: Color) -> void:
	image.fill_rect(rect, color)

static func _fallback_recipe(product_id: String) -> Dictionary:
	var hue := float(abs(product_id.hash()) % 360) / 360.0
	return {"primary": Color.from_hsv(hue, 0.65, 0.9), "accent": Color.WHITE, "kind": "packet", "stack": "tray", "mark": "fallback"}
