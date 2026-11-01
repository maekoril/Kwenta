extends Control

# Illustrative notebook page; these old paid rows are not gameplay debt records.
const HANDWRITING: Font = preload("res://assets/fonts/Caveat.ttf")
const PAGE_SIZE := Vector2(1120, 520)
const INK := Color("2b1a10")
const RED := Color("b43a32")
var page: Control
var show_paolo := false
var rosa_balance := 320

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 44
	visible = false
	var shade := ColorRect.new()
	shade.color = Color(0.06, 0.035, 0.02, 0.48)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	page = Control.new()
	page.name = "UtangLedgerPage"
	page.z_index = 7
	page.size = PAGE_SIZE
	page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.draw.connect(_draw_page)
	add_child(page)
	resized.connect(_layout_page)
	_layout_page()

func show_note(include_paolo: bool = false, current_rosa_balance: int = 320) -> void:
	show_paolo = include_paolo
	rosa_balance = current_rosa_balance
	visible = true
	_layout_page()
	page.queue_redraw()

func _layout_page() -> void:
	if not is_instance_valid(page): return
	var fit := maxf(0.1, minf(0.88, minf((size.x - 80.0) / PAGE_SIZE.x, (size.y * 0.52) / PAGE_SIZE.y)))
	page.pivot_offset = PAGE_SIZE * 0.5
	page.position = Vector2((size.x - PAGE_SIZE.x) * 0.5, 24.0 - (PAGE_SIZE.y * (1.0 - fit) * 0.5))
	page.scale = Vector2.ONE * fit

func _draw_page() -> void:
	page.draw_rect(Rect2(Vector2.ZERO, PAGE_SIZE), Color("f6e7c8"))
	page.draw_rect(Rect2(Vector2.ZERO, PAGE_SIZE), INK, false, 5.0)
	for y in range(100, 500, 56):
		page.draw_line(Vector2(18, y), Vector2(1102, y), Color("a5b8c6", 0.55), 2.0)
	page.draw_line(Vector2(75, 15), Vector2(75, 505), Color("d9857a", 0.8), 3.0)
	for y in [95, 260, 425]:
		page.draw_circle(Vector2(32, y), 12, INK)
	var font := ThemeDB.fallback_font
	page.draw_string(font, Vector2(110, 62), "KUWADERNO · UTANG", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, INK)
	page.draw_string(font, Vector2(140, 112), "PETSA", HORIZONTAL_ALIGNMENT_LEFT, -1, 23, INK)
	page.draw_string(font, Vector2(350, 112), "PANGALAN / TALA", HORIZONTAL_ALIGNMENT_LEFT, -1, 23, INK)
	page.draw_string(font, Vector2(800, 112), "HALAGA", HORIZONTAL_ALIGNMENT_LEFT, -1, 23, INK)
	var rows := [
		["03/12", "Mang Lito", "₱45", true],
		["03/18", "Mang Ramon", "₱80", true],
		["03/25", "Lola Rosa", "₱%d" % rosa_balance, false],
	]
	if show_paolo:
		rows.append(["Day 3", "Paolo", "₱3", false])
	for i in range(rows.size()):
		var row: Array = rows[i]
		var y := 178.0 + i * 80.0
		page.draw_string(HANDWRITING, Vector2(140, y), str(row[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 46, INK)
		page.draw_string(HANDWRITING, Vector2(350, y), str(row[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, 50, INK)
		page.draw_string(HANDWRITING, Vector2(800, y), str(row[2]), HORIZONTAL_ALIGNMENT_LEFT, -1, 50, INK)
		if bool(row[3]):
			page.draw_line(Vector2(135, y - 15), Vector2(930, y - 21), RED, 4.0, true)
			page.draw_string(HANDWRITING, Vector2(948, y), "PD", HORIZONTAL_ALIGNMENT_LEFT, -1, 48, RED)
