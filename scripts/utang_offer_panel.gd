extends Control

signal decided(approved: bool)

var card: PanelContainer
var items: GridContainer
var details: Label
var details_button: Button
var approve_button: Button
var decline_button: Button
var _answered := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0.08, 0.05, 0.02, 0.65)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)
	card = PanelContainer.new()
	card.add_theme_stylebox_override("panel", KwentaStyle.box(KwentaStyle.PAPER, KwentaStyle.INK, 36, 28, 18, 5))
	add_child(card)
	resized.connect(_layout)

func present(customer: CustomerState, state: CampaignState, products: Dictionary, portrait: Texture2D) -> void:
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 14)
	card.add_child(body)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 22)
	body.add_child(header)
	var face := TextureRect.new()
	face.texture = portrait
	face.custom_minimum_size = Vector2(100, 110)
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	header.add_child(face)
	var heading := VBoxContainer.new()
	header.add_child(heading)
	heading.add_child(KwentaStyle.make_label("PAUTANG", 26, KwentaStyle.INK_MUTED))
	var names := {"neighbor_lina": "Aling Lina", "neighbor_rosa": "Lola Rosa", "neighbor_nico": "Nico", "neighbor_ramon": "Mang Ramon", "jun_jun": "Jun-jun"}
	var customer_name := str(names.get(customer.customer_id, customer.customer_id.capitalize()))
	heading.add_child(KwentaStyle.make_label(customer_name, 44, Color("8b5b12") if state.is_suki(customer.customer_id) else KwentaStyle.INK))
	body.add_child(KwentaStyle.make_label("“Tonyo, puwedeng bukas ang bayad?”", 32, KwentaStyle.INK))
	if state.day == 4:
		body.add_child(KwentaStyle.make_label("Check the total and due date, then decide whether to lend.", 25, KwentaStyle.INK_MUTED))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 240
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	items = GridContainer.new()
	items.columns = 4
	items.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	items.add_theme_constant_override("h_separation", 14)
	items.add_theme_constant_override("v_separation", 12)
	scroll.add_child(items)
	for id in customer.order.requested:
		var product: ProductData = products.get(id)
		var tile := VBoxContainer.new()
		tile.custom_minimum_size.x = 220
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		items.add_child(tile)
		var icon := TextureRect.new()
		icon.texture = product.single_unit_texture if product != null else null
		icon.custom_minimum_size = Vector2(180, 130)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tile.add_child(icon)
		var quantity := KwentaStyle.make_label("×%d" % int(customer.order.requested[id]), 34, KwentaStyle.INK)
		quantity.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tile.add_child(quantity)
		var label := KwentaStyle.make_label(product.display_name if product != null else str(id), 26, KwentaStyle.INK)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tile.add_child(label)
	var repayment := HBoxContainer.new()
	body.add_child(repayment)
	var due := VBoxContainer.new()
	due.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	repayment.add_child(due)
	due.add_child(KwentaStyle.make_label("Babayaran", 30, KwentaStyle.INK_MUTED))
	due.add_child(KwentaStyle.make_label("Bukas · Day %d" % (state.day + 1), 34, KwentaStyle.INK))
	var offer := customer.credit_offer
	repayment.add_child(KwentaStyle.make_label("₱%d" % (int(offer.principal) + int(offer.interest)), 64, KwentaStyle.INK))
	body.add_child(KwentaStyle.make_label("Paninda ₱%d + dagdag ₱%d = ₱%d" % [int(offer.principal), int(offer.interest), int(offer.principal) + int(offer.interest)], 30, KwentaStyle.INK))
	details_button = Button.new()
	details_button.text = "▸ Detalye ng pautang"
	KwentaStyle.style_button(details_button, KwentaStyle.PAPER, 28)
	details_button.focus_mode = Control.FOCUS_ALL
	body.add_child(details_button)
	details = KwentaStyle.make_label("Paninda ₱%d + dagdag ₱%d\n%s%% dagdag · %s · ni-round sa piso" % [int(offer.principal), int(offer.interest), str(state.credit_rate(customer.customer_id) * 100.0), "suki" if state.is_suki(customer.customer_id) else "regular rate"], 27, KwentaStyle.INK_MUTED)
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.hide()
	body.add_child(details)
	details_button.pressed.connect(func():
		details.visible = not details.visible
		details_button.text = "▾ Itago ang detalye" if details.visible else "▸ Detalye ng pautang"
		_layout.call_deferred())
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 18)
	body.add_child(actions)
	approve_button = _action("Pautangin", KwentaStyle.GOLD, actions)
	decline_button = _action("Hindi muna", KwentaStyle.PAPER_DARK, actions)
	approve_button.pressed.connect(func(): _decide(true))
	decline_button.pressed.connect(func(): _decide(false))
	_layout.call_deferred()

func _action(text: String, color: Color, parent: Control) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 76
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	KwentaStyle.style_button(button, color, 36)
	button.focus_mode = Control.FOCUS_ALL
	parent.add_child(button)
	return button

func _decide(approved: bool) -> void:
	if _answered: return
	_answered = true
	approve_button.disabled = true
	decline_button.disabled = true
	decided.emit(approved)

func _layout() -> void:
	if card == null: return
	card.size = Vector2(1080, 0)
	var card_size := Vector2(1080, maxf(760, card.get_combined_minimum_size().y))
	card.size = card_size
	var fit := minf(1.0, minf((size.x - 48) / card_size.x, (size.y - 48) / card_size.y))
	card.scale = Vector2.ONE * maxf(0.1, fit)
	card.position = (size - card_size * card.scale) * 0.5
