extends Control

# Read-only examples: never submit money or mutate the customer's patience.
var change_due := 0
var difference := 1

func _init() -> void:
	custom_minimum_size = Vector2(590, 330)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func configure(due: int) -> void:
	change_due = due
	difference = mini(5, due)
	queue_redraw()

func _text(at: Vector2, value: String, color: Color = KwentaStyle.INK, font_size: int = 24) -> void:
	var font := KwentaStyle.font()
	if font == null:
		font = ThemeDB.fallback_font
	draw_string(font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _draw() -> void:
	var amounts := [change_due, change_due - difference, change_due + difference]
	var names := ["TAMA", "KULANG", "SOBRA"]
	var colors := [Color("2f6b2f"), Color("992f25"), Color("8b4f19")]
	for index in range(3):
		var y := float(index * 110)
		var color: Color = colors[index]
		draw_style_box(KwentaStyle.box(KwentaStyle.PAPER_DARK, color, 0, 0, 8, 2, 0), Rect2(0, y, size.x, 102))
		_text(Vector2(12, y + 28), "%s  ·  ₱%d" % [names[index], amounts[index]], color, 26)
		_draw_money(int(amounts[index]), Vector2(12, y + 42))
		_text(Vector2(238, y + 65), ">", color, 32)
		match index:
			0:
				_text(Vector2(274, y + 28), "SALE COMPLETE", color)
				_text(Vector2(274, y + 57), "Customer gets exact sukli.", KwentaStyle.INK, 22)
				_draw_meter(Vector2(274, y + 71), 1.0, color)
			1:
				_text(Vector2(274, y + 28), "PATIENCE  -%ds" % SukliRules.SHORT_PENALTY_SECONDS, color)
				_text(Vector2(274, y + 57), "Customer waits. Try again.", KwentaStyle.INK, 22)
				_draw_meter(Vector2(274, y + 71), 1.0 - SukliRules.SHORT_PENALTY_SECONDS / SukliRules.payment_patience(2), color)
			2:
				_text(Vector2(274, y + 28), "KITA  -₱%d" % difference, color)
				_text(Vector2(274, y + 57), "Sale ends; you pay the extra.", KwentaStyle.INK, 22)
				_text(Vector2(274, y + 85), "YOUR KITA  >  CUSTOMER", color, 20)

func _draw_meter(at: Vector2, fraction: float, color: Color) -> void:
	draw_rect(Rect2(at, Vector2(288, 16)), Color("c6ae88"))
	draw_rect(Rect2(at, Vector2(288 * fraction, 16)), color)
	if fraction < 1.0:
		_text(at + Vector2(288 * fraction + 5, 15), "-4s", KwentaStyle.INK, 16)

func _draw_money(amount: int, at: Vector2) -> void:
	var remaining := amount
	var x := at.x
	for denomination in [50, 20, 10, 5, 1]:
		var count := remaining / int(denomination)
		remaining %= int(denomination)
		if count == 0:
			continue
		var texture: Texture2D = CashTray.MONEY_TEXTURES[denomination]
		draw_texture_rect(texture, Rect2(x, at.y, 40, 34), false)
		_text(Vector2(x, at.y + 52), "₱%d×%d" % [denomination, count], KwentaStyle.INK, 16)
		x += 54
	if amount == 0:
		_text(at + Vector2(0, 30), "No coins given", KwentaStyle.INK_MUTED, 22)
