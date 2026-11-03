extends Control

# Illustrated examples only; this control never modifies the running shift.
const HELPERS := {
	"mikay": preload("res://assets/characters/mikay/mikay_peeking.png"),
	"jun_jun": preload("res://assets/characters/jun_jun/jun_jun_peeking.png"),
	"bogs": preload("res://assets/characters/bogs/bogs_peeking.png"),
}
const ATLAS: Texture2D = preload("res://assets/store/products/kwenta_generic_products.png")
var helper := "mikay"

func _init() -> void:
	custom_minimum_size = Vector2(590, 285)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func configure(value: String) -> void:
	helper = value
	queue_redraw()

func _text(at: Vector2, value: String, size_px: int = 23, color: Color = KwentaStyle.INK) -> void:
	var font := KwentaStyle.font()
	if font == null: font = ThemeDB.fallback_font
	draw_string(font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, color)

func _draw() -> void:
	draw_style_box(KwentaStyle.box(KwentaStyle.PAPER_DARK, KwentaStyle.INK_MUTED, 0, 0, 8, 2, 0), Rect2(0, 0, 590, 285))
	draw_texture_rect(HELPERS[helper], Rect2(8, 49, 132, 198), false)
	_text(Vector2(18, 274), "HALIMBAWA", 19, KwentaStyle.INK_MUTED)
	_text(Vector2(153, 32), "BAGO", 22, KwentaStyle.INK_MUTED)
	_text(Vector2(392, 32), "PAGKATAPOS", 22, KwentaStyle.INK_MUTED)
	_draw_card(Rect2(146, 46, 170, 160))
	_draw_card(Rect2(384, 46, 184, 160))
	_text(Vector2(331, 135), ">", 38, KwentaStyle.INK_MUTED)
	match helper:
		"mikay":
			_text(Vector2(159, 86), "Bayad  ₱50", 22)
			_text(Vector2(159, 119), "Bili     ₱35", 22)
			_text(Vector2(159, 163), "Sukli?", 23, KwentaStyle.INK_MUTED)
			_text(Vector2(396, 104), "Sukli  ₱15", 24, KwentaStyle.MONEY)
			_text(Vector2(396, 150), "Tama!", 23, KwentaStyle.MONEY)
		"jun_jun":
			_draw_products(Vector2(155, 78), ["biscuits", "instant_noodles"])
			_text(Vector2(156, 187), "1 customer", 20)
			_text(Vector2(397, 108), "ORDER", 25, KwentaStyle.MONEY)
			_text(Vector2(397, 146), "KUMPLETO", 25, KwentaStyle.MONEY)
		"bogs":
			for i in range(3):
				_text(Vector2(158, 85 + i * 42), "Order %d  ···" % (i + 1), 22)
			for i in range(3):
				_text(Vector2(397, 85 + i * 42), "Order %d  OK" % (i + 1), 22, KwentaStyle.MONEY)
	_text(Vector2(153, 248), {"mikay": "Pahinga: 20 segundo", "jun_jun": "Pahinga: 60 segundo", "bogs": "Pahinga: 120 segundo"}[helper], 22, KwentaStyle.INK_MUTED)

func _draw_card(rect: Rect2) -> void:
	draw_style_box(KwentaStyle.box(KwentaStyle.PAPER, KwentaStyle.INK_MUTED, 0, 0, 7, 2, 0), rect)

func _draw_products(at: Vector2, products: Array) -> void:
	for i in range(products.size()):
		var texture := CounterArt.product_icon(str(products[i]), ATLAS)
		if texture != null:
			draw_texture_rect(texture, Rect2(at + Vector2(i * 72, 0), Vector2(68, 78)), false)
