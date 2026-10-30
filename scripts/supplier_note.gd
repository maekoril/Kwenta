class_name SupplierNote
extends Control

signal closed

const HANDWRITING: Font = preload("res://assets/fonts/Caveat.ttf")
const PAGE_SIZE := Vector2(1080.0, 850.0)

var _page: PanelContainer
var _intro: Tween
var _product_list: Label

func _ready() -> void:
	size = StorefrontLayout.VIEWPORT_SIZE
	z_index = 55
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0.06, 0.035, 0.02, 0.68)
	dim.size = size
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	_page = PanelContainer.new()
	_page.name = "SupplierNotePage"
	_page.size = PAGE_SIZE
	_page.position = ((size - PAGE_SIZE) * 0.5).round()
	var page_style := KwentaStyle.box(KwentaStyle.PAPER, KwentaStyle.INK, 56.0, 36.0, 12, 6, 12)
	page_style.content_margin_left = 100.0
	_page.add_theme_stylebox_override("panel", page_style)
	add_child(_page)
	var paper := NotebookPaper.new()
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_page.add_child(paper)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	_page.add_child(column)
	var eyebrow := KwentaStyle.make_label("KUWADERNO NI INAY", 24, KwentaStyle.INK_MUTED)
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(eyebrow)
	var heading := _handwritten("Listahan ng Paninda", 66)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(heading)
	var rule := ColorRect.new()
	rule.color = KwentaStyle.INK
	rule.custom_minimum_size.y = 3.0
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(rule)
	_product_list = _handwritten("", 40)
	_product_list.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_product_list)
	var message := _handwritten("Anak, iiwan ko muna itong kahon dito. Aalis na ako para bumili ng gamot ni Lola. Pakihanay ang Patos, Zesty at Kapeko. Kung may ipon, puwede kang magdagdag mula sa listahan.\n— Inay", 38)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(message)
	var signature := _handwritten("", 46)
	signature.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	column.add_child(signature)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(spacer)
	var footer := CenterContainer.new()
	column.add_child(footer)
	var button := Button.new()
	button.name = "ContinueButton"
	button.text = "CONTINUE  >>"
	button.custom_minimum_size = Vector2(430.0, 90.0)
	KwentaStyle.style_button(button, KwentaStyle.GOLD, KwentaStyle.SIZE_BUTTON)
	button.pressed.connect(_dismiss)
	footer.add_child(button)

func _handwritten(value: String, font_size: int) -> Label:
	var label := KwentaStyle.make_label(value, font_size, Color("344965"))
	label.add_theme_font_override("font", HANDWRITING)
	# Give wrapped text a real width before the first container layout pass.
	label.custom_minimum_size.x = 850.0
	return label

func present() -> void:
	var config := StoreConfig.load_config("res://data/store_config.json")
	_product_list.text = "Palawit: sabon, shampoo, toothpaste     PHP %d\nTubig     PHP %d\nToyo, patis, suka     PHP %d\nMantika     PHP %d\nBigas     PHP %d" % [
		_group_price(config, "hanging_strip"), _group_price(config, "water_shelf"),
		_group_price(config, "condiments"), _group_price(config, "oil_shelf"),
		_group_price(config, "rice_shelf")]
	visible = true
	_page.reset_size()
	_page.size = PAGE_SIZE
	_page.position = ((size - _page.size) * 0.5).round()
	_page.pivot_offset = _page.size * 0.5
	_page.scale = Vector2(0.96, 0.96)
	_page.modulate.a = 0.0
	if _intro != null and _intro.is_valid():
		_intro.kill()
	_intro = create_tween().set_parallel(true)
	_intro.tween_property(_page, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_intro.tween_property(_page, "modulate:a", 1.0, 0.16)

func _group_price(config: Dictionary, group_id: String) -> int:
	for entry in config.get("products", {}).values():
		if str(entry.get("purchase_group", "")) == group_id:
			return int(entry.get("price", 0))
	return 0

func _dismiss() -> void:
	visible = false
	closed.emit()
