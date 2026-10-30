extends SceneTree

const ShelfShopModalScript = preload("res://scripts/shelf_shop_modal.gd")
const StoreConfigScript = preload("res://scripts/store_config.gd")
const MainScene = preload("res://scenes/main.tscn")

var failures := 0
var requested_purchases: Array[Dictionary] = []

func _initialize() -> void:
	var modal := ShelfShopModalScript.new() as Control
	root.add_child(modal)
	await process_frame
	modal.purchase_requested.connect(_record_purchase)
	var config: Dictionary = StoreConfigScript.load_config("res://data/store_config.json")
	modal.configure(config, [], 150)
	modal.open()
	await process_frame

	_assert(modal.get_node_or_null("SupplierShopPanel") != null, "shop builds a named wooden supplier panel")
	var panel := modal.get_node_or_null("SupplierShopPanel") as Control
	var panel_art := modal.get_node_or_null("SupplierShopPanel/PanelArt") as TextureRect
	_assert(panel_art != null and panel_art.texture != null and panel_art.texture.resource_path == "res://assets/sprites/ui/shop/supplier_shelf_panel_v3.png", "shop uses the supplied Supplier Shelf panel as its single background")
	_assert(panel_art != null and panel != null and panel_art.position == Vector2.ZERO and panel_art.size == panel.size, "composed panel art fills the complete panel bounds")
	_assert(modal.get_node_or_null("SupplierShopPanel/TitlePlaque") == null and modal.get_node_or_null("SupplierShopPanel/SubtitleStrip") == null and modal.get_node_or_null("SupplierShopPanel/CashTag") == null, "baked panel art replaces separate title, subtitle, and cash chrome")
	var modal_cash_label := modal.get_node_or_null("SupplierShopPanel/CashLabel") as Label
	_assert(modal_cash_label != null and modal_cash_label.text == "₱150", "live cash is displayed over the baked cash tag")
	var cards := modal.get_node_or_null("SupplierShopPanel/FixtureGrid") as Control
	_assert(cards != null and cards.get_child_count() == 5, "shop builds exactly one fixture card per purchase group")
	_assert(panel != null and not panel is Panel, "outer supplier panel is texture-backed instead of a generic Panel")
	var expected_button_positions := {
		"hanging_strip": Vector2(570, 348),
		"water_shelf": Vector2(1060, 348),
		"condiments": Vector2(570, 548),
		"oil_shelf": Vector2(1060, 548),
		"rice_shelf": Vector2(875, 714),
	}
	for group_id in expected_button_positions:
		var card := modal.get_node_or_null("SupplierShopPanel/FixtureGrid/FixtureCard_%s" % group_id) as Control
		_assert(card != null, "%s fixture card exists" % group_id)
		_assert(card != null and card.get_node_or_null("CardChrome") == null and card.get_node_or_null("ProductPreview") == null and card.get_node_or_null("FixtureName") == null and card.get_node_or_null("FixtureDescription") == null, "%s only overlays live actions over the baked fixture art" % group_id)
		_assert(card != null and card.position == expected_button_positions[group_id] and card.size == Vector2(160, 36), "%s action zone is mapped to its baked panel card" % group_id)
		_assert(panel != null and Rect2(Vector2.ZERO, panel.size).encloses(Rect2(card.position, card.size)), "%s stays inside the wood panel" % group_id)

	var hanging_button := modal.get_node_or_null("SupplierShopPanel/FixtureGrid/FixtureCard_hanging_strip/BuyButton") as Button
	var water_button := modal.get_node_or_null("SupplierShopPanel/FixtureGrid/FixtureCard_water_shelf/BuyButton") as Button
	var condiment_button := modal.get_node_or_null("SupplierShopPanel/FixtureGrid/FixtureCard_condiments/BuyButton") as Button
	_assert(hanging_button != null and not hanging_button.disabled and hanging_button.text == "BUY ₱150", "PHP 150 Hanging Strip is purchasable with PHP 150 cash")
	_assert(water_button != null and not water_button.disabled and water_button.text == "BUY ₱120", "PHP 120 Water Shelf is purchasable with PHP 150 cash")
	_assert(condiment_button != null and condiment_button.disabled and condiment_button.text == "NEED ₱250", "insufficient cash locks Condiment Shelf with the required caption")
	_assert(hanging_button != null and condiment_button != null and hanging_button.size == Vector2(160, 36) and condiment_button.size == hanging_button.size, "BUY and NEED buttons share the 160x36 action size")
	_assert(_button_texture_path(hanging_button) == "res://assets/sprites/ui/sukli/sized/ibigay_button.png", "purchasable fixture uses the ibigay button art")
	_assert(_button_texture_path(condiment_button) == "res://assets/sprites/ui/sukli/sized/linisin_button.png", "unaffordable fixture uses the linisin button art")
	if hanging_button != null:
		hanging_button.emit_signal("pressed")
	_assert(requested_purchases == [{"group_id": "hanging_strip", "price": 150}], "Hanging Strip button emits its group and configured price")

	modal.configure(config, ["hanging_strip"], 0)
	await process_frame
	hanging_button = modal.get_node_or_null("SupplierShopPanel/FixtureGrid/FixtureCard_hanging_strip/BuyButton") as Button
	_assert(hanging_button != null and hanging_button.disabled and hanging_button.text == "PURCHASED", "owned fixture becomes non-purchasable")
	var close_button := modal.get_node_or_null("SupplierShopPanel/CloseShop") as TextureButton
	_assert(close_button != null and close_button.texture_normal == null, "transparent close hit target uses the baked red X")
	if close_button != null:
		close_button.emit_signal("pressed")
	_assert(not modal.visible, "close button hides the modal")

	modal.queue_free()
	await _test_shop_icon_availability()
	await _test_live_purchase("hanging_strip", 0)
	await _test_live_purchase("water_shelf", 30)
	if failures > 0:
		push_error("%d shelf shop modal assertion(s) failed." % failures)
		quit(1)
	print("Shelf shop modal assertions passed.")
	quit(0)

func _record_purchase(group_id: String, price: int) -> void:
	requested_purchases.append({"group_id": group_id, "price": price})

func _test_live_purchase(group_id: String, expected_cash: int) -> void:
	var main := MainScene.instantiate() as Control
	root.add_child(main)
	await process_frame
	var campaign = main.get("campaign")
	campaign.day = 2
	main.set("shop_available", true)
	main.call("_refresh_shop_button")
	main.call("_open_shelf_shop")
	await process_frame
	var shop := main.get("shelf_shop") as Control
	var buy_button := shop.get_node_or_null("SupplierShopPanel/FixtureGrid/FixtureCard_%s/BuyButton" % group_id) as Button
	_assert(buy_button != null and not buy_button.disabled, "%s button is active in the live scene" % group_id)
	if buy_button != null:
		buy_button.emit_signal("pressed")
	await process_frame
	campaign = main.get("campaign")
	_assert(campaign != null and int(campaign.cash) == expected_cash and campaign.purchased_store_groups.has(group_id), "%s purchase deducts live campaign cash once and records ownership" % group_id)
	var cash_label := shop.get_node_or_null("SupplierShopPanel/CashLabel") as Label
	_assert(cash_label != null and cash_label.text == "₱%d" % expected_cash, "%s purchase refreshes the cash tag immediately" % group_id)
	var refreshed_button := shop.get_node_or_null("SupplierShopPanel/FixtureGrid/FixtureCard_%s/BuyButton" % group_id) as Button
	_assert(refreshed_button != null and refreshed_button.disabled and refreshed_button.text == "PURCHASED", "%s purchase refreshes its button state immediately" % group_id)
	main.queue_free()

func _test_shop_icon_availability() -> void:
	var main := MainScene.instantiate() as Control
	root.add_child(main)
	await process_frame
	var shop_button := main.find_child("ShopIconButton", true, false) as Button
	var shop_icon := main.find_child("ShopIcon", true, false) as TextureRect
	var bubble := main.get("bubble") as Control
	_assert(shop_button != null and not shop_button.visible, "Shop icon stays hidden on Day 1")
	_assert(shop_button != null and shop_button.size == Vector2(72, 72) and shop_button.z_index == 55 and _button_texture_path(shop_button) == "res://assets/sprites/ui/sukli/sized/ibigay_button.png", "Shop icon uses the ibigay texture as a compact square button above dialogue")
	_assert(shop_icon != null and shop_icon.texture != null and shop_icon.texture.resource_path == "res://assets/sprites/ui/shop/lucide_store.svg" and shop_icon.size == Vector2(40, 40), "Shop icon uses the hollow Lucide Store art")
	_assert(shop_button != null and shop_button.get_parent() == main and bubble != null and shop_button.get_index() > bubble.get_index(), "Shop icon is added after dialogue so it receives taps first")
	var campaign = main.get("campaign")
	campaign.day = 2
	main.set("shop_available", true)
	main.call("_refresh_shop_button")
	_assert(shop_button != null and shop_button.visible, "Shop icon appears before Day 2 starts")
	if shop_button != null:
		shop_button.emit_signal("pressed")
	var shop := main.get("shelf_shop") as Control
	_assert(shop != null and shop.visible and shop.z_index == 60 and shop.get_index() > bubble.get_index() and not bool(main.get("shift_in_progress")), "opening the pre-shift shop moves it above dialogue while gameplay stays paused")
	if shop != null:
		shop.call("close")
	main.call("_begin_shift")
	_assert(shop_button != null and not shop_button.visible, "Shop icon hides when the shift starts")
	main.call("_open_shelf_shop")
	_assert(shop != null and not shop.visible, "shop cannot open during an active shift")
	main.queue_free()

func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error("FAIL: %s" % message)

func _button_texture_path(button: Button) -> String:
	if button == null:
		return ""
	var style := button.get_theme_stylebox("normal") as StyleBoxTexture
	if style == null or style.texture == null:
		return ""
	return style.texture.resource_path
