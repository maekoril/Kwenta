class_name ShelfShopModal
extends Control

signal purchase_requested(group_id: String, price: int)
signal closed

const FRAME_TEXTURE := preload("res://assets/sprites/ui/shop/supplier_shelf_panel_v3.png")
const BUY_BUTTON_TEXTURE := preload("res://assets/sprites/ui/sukli/sized/ibigay_button.png")
const NEED_BUTTON_TEXTURE := preload("res://assets/sprites/ui/sukli/sized/linisin_button.png")

const PANEL_SIZE := Vector2(1510, 850)
const PANEL_POSITION := Vector2(205, 104)
const ACTION_BUTTON_SIZE := Vector2(160, 36)
const ACTION_BUTTON_POSITIONS := {
	"hanging_strip": Vector2(570, 348),
	"water_shelf": Vector2(1060, 348),
	"condiments": Vector2(570, 548),
	"oil_shelf": Vector2(1060, 548),
	"rice_shelf": Vector2(875, 714),
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
	visible = false
	if _confirmation_tween != null and _confirmation_tween.is_valid():
		_confirmation_tween.kill()
	if _confirmation != null:
		_confirmation.visible = false
	closed.emit()

func show_purchase_confirmation(product_names: Array[String]) -> void:
	if _confirmation == null:
		return
	if _confirmation_tween != null and _confirmation_tween.is_valid():
		_confirmation_tween.kill()
	_confirmation_label.text = "Now available: %s" % ", ".join(product_names)
	_confirmation.modulate.a = 1.0
	_confirmation.visible = true
	_confirmation_tween = create_tween()
	_confirmation_tween.tween_interval(3.0)
	_confirmation_tween.tween_property(_confirmation, "modulate:a", 0.0, 0.3)
	_confirmation_tween.tween_callback(_confirmation.hide)

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

	var frame := _texture_rect("PanelArt", FRAME_TEXTURE, Vector2.ZERO, PANEL_SIZE)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(frame)

	# Cover the baked-in fixture copy with an explanation of what the order does.
	var supplier_note := PanelContainer.new()
	supplier_note.name = "SupplierExplanation"
	supplier_note.position = Vector2(419, 153)
	supplier_note.size = Vector2(674, 37)
	supplier_note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	supplier_note.add_theme_stylebox_override("panel", KwentaStyle.box(Color("f8dfb0"), Color("f8dfb0"), 2.0, 1.0, 0, 0, 0))
	panel.add_child(supplier_note)
	var explanation := KwentaStyle.make_label("Order once: products stay stocked and customers can request them.", 19, KwentaStyle.INK)
	explanation.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	explanation.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	supplier_note.add_child(explanation)

	_cash_label = KwentaStyle.make_label("", 27, Color("24572d"))
	_cash_label.name = "CashLabel"
	_cash_label.position = Vector2(1102, 112)
	_cash_label.size = Vector2(168, 50)
	_cash_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cash_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_cash_label.add_theme_color_override("font_outline_color", Color("eff7df"))
	_cash_label.add_theme_constant_override("outline_size", 3)
	_cash_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(_cash_label)

	var close_button := TextureButton.new()
	close_button.name = "CloseShop"
	close_button.position = Vector2(1262, 64)
	close_button.size = Vector2(140, 130)
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.tooltip_text = "Close shop"
	close_button.pressed.connect(close)
	panel.add_child(close_button)

	_fixture_grid = Control.new()
	_fixture_grid.name = "FixtureGrid"
	_fixture_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fixture_grid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(_fixture_grid)

	_confirmation = PanelContainer.new()
	_confirmation.name = "PurchaseConfirmation"
	_confirmation.position = Vector2(350, 196)
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

func _make_fixture_card(group_id: String, products: Dictionary) -> Control:
	var card := Control.new()
	card.size = ACTION_BUTTON_SIZE
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	var price := _group_price(group_id, products)

	var buy_button := Button.new()
	buy_button.name = "BuyButton"
	buy_button.position = Vector2.ZERO
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
		buy_button.text = "BUY ₱%d" % price
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
