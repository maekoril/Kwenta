extends SceneTree

const ShelfShopModalScript = preload("res://scripts/shelf_shop_modal.gd")
const StoreConfigScript = preload("res://scripts/store_config.gd")
const MainScene = preload("res://scenes/main.tscn")

var failures := 0
var requested_purchases: Array[Dictionary] = []

func _initialize() -> void:
	var modal := ShelfShopModalScript.new() as Control
	var phone_viewport := Control.new()
	phone_viewport.size = Vector2(945.0, 430.0)
	root.add_child(phone_viewport)
	phone_viewport.add_child(modal)
	await process_frame
	modal.purchase_requested.connect(_record_purchase)
	var config: Dictionary = StoreConfigScript.load_config("res://data/store_config.json")
	modal.configure(config, [], 150)
	modal.open()
	await process_frame

	_assert(modal.get_node_or_null("SupplierShopPanel") != null, "shop builds a named wooden supplier panel")
	var panel := modal.get_node_or_null("SupplierShopPanel") as Control
	_assert(panel != null and Rect2(Vector2.ZERO, phone_viewport.size).encloses(panel.get_global_rect()), "shop panel stays fully visible on a phone-sized viewport")
	_assert(panel != null and absf(panel.get_global_rect().get_center().x - phone_viewport.size.x * 0.5) <= 1.0, "shop panel stays horizontally centered on a phone-sized viewport")
	_assert(modal.get_node_or_null("SupplierShopPanel/NotebookPage") != null, "shop displays Inay's notebook")
	var modal_cash_label := modal.get_node_or_null("SupplierShopPanel/CashLabel") as Label
	_assert(modal_cash_label != null and modal_cash_label.text == "₱150", "live cash is displayed")
	var cards := modal.get_node_or_null("SupplierShopPanel/FixtureGrid") as Control
	_assert(cards != null and cards.get_child_count() == 5, "shop builds five supplier options")
	modal.show_order_tutorial()
	await process_frame
	await process_frame
	await process_frame
	var tutorial_outline := modal.get_node_or_null("SupplierShopPanel/SupplierTutorialOutline") as Control
	_assert(tutorial_outline != null and tutorial_outline.visible, "tutorial highlights an affordable order")
	modal.hide_order_tutorial()
	for group_id in ["hanging_strip", "water_shelf", "condiments", "oil_shelf", "rice_shelf"]:
		var card := modal.get_node_or_null("SupplierShopPanel/FixtureGrid/FixtureCard_%s" % group_id) as Control
		_assert(card != null and card.get_node_or_null("ProductPreview") != null, "%s shows a product preview" % group_id)
		_assert(panel != null and card != null and Rect2(Vector2.ZERO, panel.size).encloses(Rect2(card.position, card.size)), "%s stays inside the notebook" % group_id)

	var hanging_button := modal.get_node_or_null("SupplierShopPanel/FixtureGrid/FixtureCard_hanging_strip/BuyButton") as Button
	var water_button := modal.get_node_or_null("SupplierShopPanel/FixtureGrid/FixtureCard_water_shelf/BuyButton") as Button
	var condiment_button := modal.get_node_or_null("SupplierShopPanel/FixtureGrid/FixtureCard_condiments/BuyButton") as Button
	_assert(hanging_button != null and not hanging_button.disabled and hanging_button.text == "ORDER ₱150", "PHP 150 Hanging Strip is purchasable with PHP 150 cash")
	_assert(water_button != null and not water_button.disabled and water_button.text == "ORDER ₱120", "PHP 120 Water Shelf is purchasable with PHP 150 cash")
	_assert(condiment_button != null and condiment_button.disabled and condiment_button.text == "NEED ₱250", "insufficient cash locks Condiment Shelf with the required caption")
	_assert(hanging_button != null and condiment_button != null and hanging_button.size == Vector2(185, 55) and condiment_button.size == hanging_button.size, "BUY and NEED buttons share the 160x36 action size")
	_assert(_button_texture_path(hanging_button) == "res://assets/sprites/ui/sukli/sized/ibigay_button.png", "purchasable fixture uses the ibigay button art")
	_assert(_button_texture_path(condiment_button) == "res://assets/sprites/ui/sukli/sized/linisin_button.png", "unaffordable fixture uses the linisin button art")
	if hanging_button != null:
		hanging_button.emit_signal("pressed")
	_assert(requested_purchases == [{"group_id": "hanging_strip", "price": 150}], "Hanging Strip button emits its group and configured price")

	modal.configure(config, ["hanging_strip"], 0)
	await process_frame
	hanging_button = modal.get_node_or_null("SupplierShopPanel/FixtureGrid/FixtureCard_hanging_strip/BuyButton") as Button
	_assert(hanging_button != null and hanging_button.disabled and hanging_button.text == "PURCHASED", "owned fixture becomes non-purchasable")
	var close_button := modal.get_node_or_null("SupplierShopPanel/CloseShop") as Button
	_assert(close_button != null and close_button.text == "X", "notebook has a visible close button")
	if close_button != null:
		close_button.emit_signal("pressed")
	_assert(not modal.visible, "close button hides the modal")

	phone_viewport.queue_free()
	await _test_shop_icon_availability()
	await _test_shop_grace_period()
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
	_assert(not shop.visible and main.story_after_action == "supplier_delivery_done" and main.bubble.visible, "purchase starts a tap-through delivery at the storefront")
	_assert(main.story_beats.size() >= 4 and main.story_beats[0].text == "Tao po!", "first delivery has Ben and Tonyo's introduction")
	var renderer := main.get("store_layer_renderer") as Control
	var config: Dictionary = StoreConfigScript.load_config("res://data/store_config.json")
	for product_id in config.get("products", {}):
		var entry: Dictionary = config.products[product_id]
		if str(entry.get("purchase_group", "")) != group_id:
			continue
		_assert(renderer != null and renderer.get_node_or_null("Slots/%s_product" % product_id) != null, "%s product art appears in the storefront after purchase" % product_id)
		_assert(main.get("product_items_by_id").has(str(entry.get("game_product_id", ""))), "%s becomes draggable after purchase" % product_id)
	main._complete_story_beats()
	_assert(shop.visible and bool(main.completed_tutorials.get("supplier_first_delivery", false)), "finishing delivery returns to the supplier list")
	if group_id == "water_shelf":
		campaign.cash = 1000
		main._on_shelf_shop_purchase_requested("oil_shelf", 200)
		_assert(main.story_beats.size() == 1 and main.story_beats[0].text.contains("Delivered na"), "later delivery uses a short returning-customer greeting")
		main._complete_story_beats()
		_assert(shop.visible, "later delivery returns to the shop")
	main.queue_free()

func _test_shop_icon_availability() -> void:
	var main := MainScene.instantiate() as Control
	root.add_child(main)
	await process_frame
	var shop_button := main.find_child("ShopIconButton", true, false) as Button
	var shop_icon := main.find_child("ShopIcon", true, false) as TextureRect
	var bubble := main.get("bubble") as Control
	_assert(shop_button != null and not shop_button.visible, "Shop icon stays hidden on Day 1")
	_assert(shop_button != null and shop_button.size == Vector2(74, 74) and shop_button.z_index == 55 and shop_button.text.is_empty(), "supplier list uses an icon-only notebook button above dialogue")
	_assert(shop_button != null and shop_button.get_node_or_null("SupplierNotebookIcon") != null, "supplier button displays a notebook icon")
	_assert(shop_icon == null, "supplier list no longer uses the floating store icon")
	_assert(shop_button != null and shop_button.get_parent() == main, "Shop icon is attached to the main UI")
	var campaign = main.get("campaign")
	campaign.day = 2
	main.set("shop_available", true)
	main.call("_refresh_shop_button")
	_assert(shop_button != null and shop_button.visible, "Shop icon appears before Day 2 starts")
	var story_beats: Array[Dictionary] = [{"speaker": "Narrator", "text": "Story in progress"}]
	main._show_story_beats(story_beats, "DAY 2", "day1_intro")
	_assert(not shop_button.visible and not main._is_shop_available(), "shop is unavailable during the pre-shift story")
	main._open_shelf_shop()
	_assert(not main.shelf_shop.visible and main.story_beats[0].text == "Story in progress", "the shop cannot replace active story dialogue")
	main.supplier_story_blocked = false
	main.bubble.close()
	main._refresh_shop_button()
	var pause_button := main.pause_menu.get("_button") as Control
	_assert(shop_button != null and pause_button != null and is_equal_approx(shop_button.position.x + shop_button.size.x * 0.5, pause_button.position.x + pause_button.size.x * 0.5) and shop_button.position.y >= pause_button.position.y + pause_button.size.y, "Shop icon is centered below the pause control")
	# Story setup moves its dialogue bubble to the top of the tree. The shop must
	# be moved back above it whenever it is available, or the bubble eats the tap.
	_assert(shop_button != null and bubble != null and shop_button.get_index() > bubble.get_index(), "Shop icon stays above the dialogue bubble after story setup")
	if shop_button != null:
		shop_button.emit_signal("pressed")
	var shop := main.get("shelf_shop") as Control
	_assert(shop != null and shop.visible and shop.z_index == 60 and shop.get_index() > bubble.get_index() and not bool(main.get("shift_in_progress")), "opening the pre-shift shop moves it above dialogue while gameplay stays paused")
	if shop != null:
		shop.call("close")
	main.call("_begin_shift")
	_assert(shop_button != null and shop_button.visible and not shop_button.disabled, "Shop icon stays visible and tappable when the shift starts")
	_assert(bool((shop_button.material as ShaderMaterial).get_shader_parameter("grayscale")), "Disabled shop icon is grayscale")
	shop_button.emit_signal("pressed")
	_assert(shop != null and not shop.visible, "shop cannot open during an active shift")
	_assert(main.get_node_or_null("ShopUnavailableNotice") != null, "tapping the locked shop explains that it is unavailable")
	main._show_shift_summary()
	_assert(not shop_button.visible, "locked shop icon disappears when the shift ends")
	main.queue_free()

func _test_shop_grace_period() -> void:
	var main := MainScene.instantiate() as Control
	root.add_child(main)
	await process_frame
	var campaign = main.get("campaign")
	campaign.day = 2
	main.set("shop_available", true)
	main.set("shift_in_progress", false)
	_assert(bool(main.call("_is_shop_available")), "Shop is available before opening")
	main.set("shift_in_progress", true)
	_assert(not bool(main.call("_is_shop_available")), "Shop is unavailable once the shift starts")
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
