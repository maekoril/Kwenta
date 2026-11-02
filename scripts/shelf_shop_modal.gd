class_name ShelfShopModal
extends Control

signal purchase_requested(group_id: String, price: int)
signal closed

const BUY_BUTTON_TEXTURE := preload("res://assets/sprites/ui/sukli/sized/ibigay_button.png")
const NEED_BUTTON_TEXTURE := preload("res://assets/sprites/ui/sukli/sized/linisin_button.png")
const DELIVERY_PORTRAIT := preload("res://assets/sprites/ui/shop/supplier_delivery.png")

const PANEL_SIZE := Vector2(1510, 850)
const PANEL_POSITION := Vector2(205, 104)
const ACTION_BUTTON_SIZE := Vector2(185, 55)
const ACTION_BUTTON_POSITIONS := {
	"hanging_strip": Vector2(95, 245),
	"water_shelf": Vector2(770, 245),
	"condiments": Vector2(95, 425),
	"oil_shelf": Vector2(770, 425),
	"rice_shelf": Vector2(95, 605),
}
const FIXTURE_COPY := {
	"hanging_strip": ["Hanging Strip", "Laundry, shampoo, toothpaste"],
	"water_shelf": ["Water Shelf", "Bottled water"],
	"condiments": ["Condiment Shelf", "Toyo, patis, suka"],
	"oil_shelf": ["Oil Shelf", "Cooking oil"],
	"rice_shelf": ["Rice Shelf", "Rice"],
}
const FIXTURES := [
	"hanging_strip",
	"water_shelf",
	"condiments",
	"oil_shelf",
	"rice_shelf",
]

var cash := 0
var purchased_groups: Array = []
var config: Dictionary = {}
var _cash_label: Label
var _panel: Control
var _fixture_grid: Control
var _confirmation: PanelContainer
var _confirmation_label: Label
var _confirmation_tween: Tween
var _delivery_portrait: TextureRect
var _tutorial_hint: Label
var _tutorial_outline: Panel

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 60
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_build_shell()
	resized.connect(_layout_panel)

func configure(shop_config: Dictionary, owned_groups: Array, current_cash: int) -> void:
	config = shop_config
	purchased_groups = owned_groups.duplicate()
	cash = current_cash
	if is_node_ready():
		_update_cash_label()
		_request_fixture_render()

func open() -> void:
	visible = true
	_layout_panel()
	_update_cash_label()
	_request_fixture_render()

func close() -> void:
	hide_order_tutorial()
	visible = false
	if _confirmation_tween != null and _confirmation_tween.is_valid():
		_confirmation_tween.kill()
	if _confirmation != null:
		_confirmation.visible = false
	if _delivery_portrait != null:
		_delivery_portrait.visible = false
	closed.emit()

func show_purchase_confirmation(product_names: Array[String]) -> void:
	if _confirmation == null:
		return
	if _confirmation_tween != null and _confirmation_tween.is_valid():
		_confirmation_tween.kill()
	_confirmation_label.text = "Kuya Ben: Heto na ang order mo!  %s" % ", ".join(product_names)
	_confirmation.modulate.a = 1.0
	_confirmation.visible = true
	_delivery_portrait.position.x = 40
	_delivery_portrait.modulate.a = 0.0
	_delivery_portrait.visible = true
	_confirmation_tween = create_tween()
	_confirmation_tween.set_parallel(true)
	_confirmation_tween.tween_property(_delivery_portrait, "position:x", 105.0, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_confirmation_tween.tween_property(_delivery_portrait, "modulate:a", 1.0, 0.2)
	_confirmation_tween.set_parallel(false)
	_confirmation_tween.tween_interval(3.0)
	_confirmation_tween.set_parallel(true)
	_confirmation_tween.tween_property(_confirmation, "modulate:a", 0.0, 0.3)
	_confirmation_tween.tween_property(_delivery_portrait, "modulate:a", 0.0, 0.3)
	_confirmation_tween.set_parallel(false)
	_confirmation_tween.tween_callback(_confirmation.hide)
	_confirmation_tween.tween_callback(_delivery_portrait.hide)

func _build_shell() -> void:
	var dimmer := ColorRect.new()
	dimmer.name = "ShopDimmer"
	dimmer.color = Color(0.0, 0.0, 0.0, 0.35)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dimmer)

	_panel = Control.new()
	_panel.name = "SupplierShopPanel"
	_panel.size = PANEL_SIZE
	_panel.pivot_offset = PANEL_SIZE * 0.5
	add_child(_panel)
	_layout_panel()
	var panel := _panel

	var page := Panel.new()
	page.name = "NotebookPage"
	page.size = PANEL_SIZE
	page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_theme_stylebox_override("panel", KwentaStyle.box(Color("f6e7c8"), Color("704729"), 0, 0, 20, 12, 8))
	panel.add_child(page)
	var heading := KwentaStyle.make_label("LISTAHAN NI INAY", 48, KwentaStyle.INK)
	heading.position = Vector2(95, 40)
	panel.add_child(heading)
	var explanation := KwentaStyle.make_label("KUYA BEN  •  SUPPLIER\nPumili ng paninda at tumawag bago magbukas.", 25, KwentaStyle.INK_MUTED)
	explanation.position = Vector2(98, 110)
	panel.add_child(explanation)
	var rule := ColorRect.new()
	rule.position = Vector2(95, 205)
	rule.size = Vector2(1320, 3)
	rule.color = Color("b68b69")
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(rule)

	_cash_label = KwentaStyle.make_label("", 27, Color("24572d"))
	_cash_label.name = "CashLabel"
	_cash_label.position = Vector2(1100, 95)
	_cash_label.size = Vector2(250, 50)
	_cash_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cash_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_cash_label.add_theme_color_override("font_outline_color", Color("eff7df"))
	_cash_label.add_theme_constant_override("outline_size", 3)
	_cash_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(_cash_label)

	var close_button := Button.new()
	close_button.name = "CloseShop"
	close_button.position = Vector2(1370, 35)
	close_button.size = Vector2(85, 70)
	close_button.text = "X"
	KwentaStyle.style_button(close_button, KwentaStyle.PAPER_DARK, 32)
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.tooltip_text = "Close shop"
	close_button.pressed.connect(close)
	panel.add_child(close_button)

	_fixture_grid = Control.new()
	_fixture_grid.name = "FixtureGrid"
	_fixture_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fixture_grid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(_fixture_grid)
	_tutorial_hint = KwentaStyle.make_label("", 24, Color("265432"))
	_tutorial_hint.name = "SupplierTutorialHint"
	_tutorial_hint.position = Vector2(100, 205)
	_tutorial_hint.size = Vector2(1200, 36)
	_tutorial_hint.z_index = 5
	_tutorial_hint.visible = false
	panel.add_child(_tutorial_hint)
	_tutorial_outline = Panel.new()
	_tutorial_outline.name = "SupplierTutorialOutline"
	_tutorial_outline.z_index = 5
	_tutorial_outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var outline_style := StyleBoxFlat.new()
	outline_style.bg_color = Color(0, 0, 0, 0)
	outline_style.border_color = Color("e3a729")
	outline_style.set_border_width_all(5)
	outline_style.set_corner_radius_all(8)
	_tutorial_outline.add_theme_stylebox_override("panel", outline_style)
	_tutorial_outline.visible = false
	panel.add_child(_tutorial_outline)

	_confirmation = PanelContainer.new()
	_confirmation.name = "PurchaseConfirmation"
	_confirmation.position = Vector2(350, 150)
	_confirmation.size = Vector2(810, 58)
	_confirmation.z_index = 2
	_confirmation.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_confirmation.add_theme_stylebox_override("panel", KwentaStyle.box(KwentaStyle.PAPER, KwentaStyle.INK, 16.0, 8.0, 8, 3, 4))
	_confirmation.visible = false
	panel.add_child(_confirmation)
	_confirmation_label = KwentaStyle.make_label("", 23, KwentaStyle.INK)
	_confirmation_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_confirmation_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_confirmation.add_child(_confirmation_label)

	_delivery_portrait = TextureRect.new()
	_delivery_portrait.name = "SupplierDeliveryPortrait"
	_delivery_portrait.position = Vector2(105, 210)
	_delivery_portrait.size = Vector2(220, 330)
	_delivery_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_delivery_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_delivery_portrait.texture = DELIVERY_PORTRAIT
	_delivery_portrait.z_index = 2
	_delivery_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_delivery_portrait.visible = false
	panel.add_child(_delivery_portrait)

func _layout_panel() -> void:
	if not is_instance_valid(_panel) or size == Vector2.ZERO:
		return
	var fit := minf(1.0, minf((size.x - 48.0) / PANEL_SIZE.x, (size.y - 48.0) / PANEL_SIZE.y))
	_panel.position = ((size - PANEL_SIZE) * 0.5).round()
	_panel.scale = Vector2.ONE * fit

func _render_fixture_cards() -> void:
	if _fixture_grid == null:
		return
	for child in _fixture_grid.get_children():
		child.free()
	var products: Dictionary = config.get("products", {})
	for group_id in FIXTURES:
		var card := _make_fixture_card(group_id, products)
		card.name = "FixtureCard_%s" % group_id
		card.position = ACTION_BUTTON_POSITIONS[group_id]
		_fixture_grid.add_child(card)

func _request_fixture_render() -> void:
	call_deferred("_render_fixture_cards")

func show_order_tutorial() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if not visible:
		return
	_tutorial_hint.text = "Pumili ng paninda. Tap ORDER para tumawag kay Kuya Ben!"
	_tutorial_hint.visible = true
	for group_id in FIXTURES:
		var card := _fixture_grid.get_node_or_null("FixtureCard_%s" % group_id) as Control
		var button := card.get_node_or_null("BuyButton") as Button if card != null else null
		if button != null and not button.disabled:
			_tutorial_outline.position = card.position + button.position - Vector2(6, 6)
			_tutorial_outline.size = button.size + Vector2(12, 12)
			_tutorial_outline.visible = true
			return
	_tutorial_hint.text = "Wala pang kayang bilhin? Tap X. Puwede kang umorder sa susunod."

func show_tutorial_close_hint() -> void:
	_tutorial_hint.text = "Ayos! Puwede pang umorder, o tap X para magpatuloy."
	_tutorial_hint.visible = true
	_tutorial_outline.position = Vector2(1364, 29)
	_tutorial_outline.size = Vector2(97, 82)
	_tutorial_outline.visible = true

func hide_order_tutorial() -> void:
	if _tutorial_hint != null:
		_tutorial_hint.visible = false
	if _tutorial_outline != null:
		_tutorial_outline.visible = false

func _make_fixture_card(group_id: String, products: Dictionary) -> Control:
	var card := Control.new()
	card.size = Vector2(600, 160)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var price := _group_price(group_id, products)
	var background := Panel.new()
	background.name = "CardChrome"
	background.size = card.size
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.add_theme_stylebox_override("panel", KwentaStyle.box(Color("fff5dc"), Color("c9a77c"), 0, 0, 8, 2, 2))
	card.add_child(background)
	var preview := TextureRect.new()
	preview.name = "ProductPreview"
	preview.position = Vector2(14, 12)
	preview.size = Vector2(115, 136)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for entry in products.values():
		if str(entry.get("purchase_group", "")) == group_id:
			preview.texture = load(str(entry.get("texture_path", ""))) as Texture2D
			break
	card.add_child(preview)
	var title := KwentaStyle.make_label(FIXTURE_COPY[group_id][0], 28, KwentaStyle.INK)
	title.position = Vector2(140, 10)
	card.add_child(title)
	var description := KwentaStyle.make_label(FIXTURE_COPY[group_id][1], 21, KwentaStyle.INK_MUTED)
	description.position = Vector2(140, 48)
	card.add_child(description)

	var buy_button := Button.new()
	buy_button.name = "BuyButton"
	buy_button.position = Vector2(390, 93)
	buy_button.size = ACTION_BUTTON_SIZE
	buy_button.focus_mode = Control.FOCUS_NONE
	buy_button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	var button_texture := BUY_BUTTON_TEXTURE
	if purchased_groups.has(group_id):
		buy_button.text = "PURCHASED"
		buy_button.disabled = true
		button_texture = NEED_BUTTON_TEXTURE
	elif cash < price:
		buy_button.text = "NEED ₱%d" % price
		buy_button.disabled = true
		button_texture = NEED_BUTTON_TEXTURE
	else:
		buy_button.text = "ORDER ₱%d" % price
		buy_button.pressed.connect(func() -> void: purchase_requested.emit(group_id, price))
	_style_buy_button(buy_button, button_texture)
	card.add_child(buy_button)
	return card

func _group_price(group_id: String, products: Dictionary) -> int:
	for product_id in products:
		var entry: Dictionary = products[product_id]
		if str(entry.get("purchase_group", "")) == group_id:
			return int(entry.get("price", 0))
	return 0

func _update_cash_label() -> void:
	if _cash_label != null:
		_cash_label.text = "₱%d" % cash

func _style_buy_button(button: Button, texture: Texture2D) -> void:
	KwentaStyle.apply_font(button)
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", KwentaStyle.INK)
	button.add_theme_color_override("font_hover_color", KwentaStyle.INK)
	button.add_theme_color_override("font_pressed_color", KwentaStyle.INK)
	button.add_theme_color_override("font_disabled_color", Color("6d5c49"))
	button.add_theme_stylebox_override("normal", _button_box(texture))
	button.add_theme_stylebox_override("hover", _button_box(texture))
	button.add_theme_stylebox_override("pressed", _button_box(texture))
	button.add_theme_stylebox_override("disabled", _button_box(texture))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

func _button_box(texture: Texture2D) -> StyleBox:
	if texture == null:
		return StyleBoxEmpty.new()
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.set_texture_margin_all(8)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	return style

func _texture_rect(node_name: String, texture: Texture2D, at: Vector2, texture_size: Vector2) -> TextureRect:
	var rect := TextureRect.new()
	rect.name = node_name
	rect.texture = texture
	rect.position = at
	rect.size = texture_size
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	return rect
