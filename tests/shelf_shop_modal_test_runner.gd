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
	_assert(hanging_button != null, "selectable hanging strip exists")
	if hanging_button != null:
		hanging_button.emit_signal("pressed")
	await process_frame
	var order_button := modal.get_node_or_null("SupplierShopPanel/OrderDetail/OrderButton") as Button
	_assert(order_button != null and not order_button.disabled, "affordable selection can be ordered")
	if order_button != null:
		order_button.emit_signal("pressed")
	_assert(requested_purchases == [{"group_id": "hanging_strip", "price": 150}], "order emits selected group and price")
	modal.configure(config, ["hanging_strip"], 0)
	await process_frame
	order_button = modal.get_node_or_null("SupplierShopPanel/OrderDetail/OrderButton") as Button
	_assert(order_button != null and order_button.disabled, "owned fixture cannot be ordered again")
	var close_button := modal.get_node_or_null("SupplierShopPanel/CloseShop") as Button
	_assert(close_button != null and close_button.text == "X", "notebook has a visible close button")
	if close_button != null:
		close_button.emit_signal("pressed")
	_assert(not modal.visible, "close button hides the modal")

	phone_viewport.queue_free()
	await _test_shop_icon_availability()
	await _test_shop_grace_period()
	await _test_supplier_note_stays_above_dialogue_input()
	await _test_live_purchase("hanging_strip", 0)
	await _test_live_purchase("water_shelf", 30)
	if failures > 0:
		push_error("%d shelf shop modal assertion(s) failed." % failures)
		quit(1)
		return
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
	var order_button := shop.get_node_or_null("SupplierShopPanel/OrderDetail/OrderButton") as Button
	_assert(order_button != null and not order_button.disabled, "selected group can be ordered")
	if order_button != null:
		order_button.emit_signal("pressed")
	await process_frame
	campaign = main.get("campaign")
	_assert(campaign != null and int(campaign.cash) == expected_cash and campaign.purchased_store_groups.has(group_id), "%s purchase deducts live campaign cash once and records ownership" % group_id)
	var cash_label := shop.get_node_or_null("SupplierShopPanel/CashLabel") as Label
	_assert(cash_label != null and cash_label.text == "₱%d" % expected_cash, "%s purchase refreshes the cash tag immediately" % group_id)
	var refreshed_button := shop.get_node_or_null("SupplierShopPanel/OrderDetail/OrderButton") as Button
	_assert(refreshed_button != null and refreshed_button.disabled, "%s cannot be ordered twice" % group_id)
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
	var row := main.get("utility_shop") as Button
	var drawer := main.get("utility_drawer") as Control
	_assert(row != null and not row.visible, "supplier row stays hidden on Day 1")
	main.campaign.day = 2
	main.shop_available = true
	main.supplier_story_blocked = false
	main.utility_toggle.pressed.emit()
	_assert(drawer.visible and row.visible and not row.disabled, "Day 2 menu exposes the supplier row")
	var beats: Array[Dictionary] = [{"speaker": "Narrator", "text": "Story in progress"}]
	main._show_story_beats(beats, "DAY 2", "day1_intro")
	main._refresh_utility_drawer()
	_assert(not main._is_shop_available() and row.disabled, "story blocks supplier ordering")
	main._open_shelf_shop()
	_assert(not main.shelf_shop.visible and main.story_beats[0].text == "Story in progress", "ordering cannot replace active story dialogue")
	main.supplier_story_blocked = false
	main.bubble.close()
	main._refresh_utility_drawer()
	row.pressed.emit()
	_assert(main.shelf_shop.visible and not drawer.visible, "supplier row opens the shop and closes the drawer")
	_assert(main.shelf_shop.z_index > drawer.z_index, "shop stays above menu input")
	main.shelf_shop.close()
	main._begin_shift()
	main.utility_open = true
	main._refresh_utility_drawer()
	_assert(row.visible and row.tooltip_text.contains("before opening"), "active shift explains ordering availability in the menu")
	row.pressed.emit()
	_assert(not main.shelf_shop.visible, "supplier row cannot order during an active shift")
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

func _test_supplier_note_stays_above_dialogue_input() -> void:
	var main := MainScene.instantiate() as Control
	root.add_child(main)
	await process_frame
	var note := main.get("supplier_note") as Control
	var bubble := main.get("bubble") as Control
	var initial_note_index := note.get_index()
	note.call("present")
	await process_frame
	_assert(note != null and bubble != null and note.visible and note.get_index() > bubble.get_index(), "supplier note moves above the dialogue bubble before it accepts CONTINUE input")
	var continue_button := note.find_child("ContinueButton", true, false) as Button
	if continue_button != null:
		continue_button.emit_signal("pressed")
	_assert(note != null and not note.visible and note.get_index() == initial_note_index and note.get_index() < bubble.get_index(), "supplier-note CONTINUE restores the note behind dialogue and tutorial layers")
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
