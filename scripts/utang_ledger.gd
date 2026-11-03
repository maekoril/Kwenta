extends Control

# Historical paid rows accompany persistent campaign debt records.
const HANDWRITING: Font = preload("res://assets/fonts/Caveat.ttf")
const PAGE_SIZE := Vector2(1120, 520)
const INK := Color("2b1a10")
const RED := Color("b43a32")
const FIRST_DAY_UNIX := 1706054400 # January 24, 2024, at midnight UTC.
var records: Array = []
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
	# Keep the lower portion clear for narration and character dialogue.
	var top_margin := 24.0
	var dialogue_clearance := size.y * 0.57
	var fit := maxf(0.1, minf(1.05, minf((size.x - 80.0) / PAGE_SIZE.x, (dialogue_clearance - top_margin) / PAGE_SIZE.y)))
	page.pivot_offset = PAGE_SIZE * 0.5
	var visual_top := top_margin + (dialogue_clearance - top_margin - PAGE_SIZE.y * fit) * 0.5
	page.position = Vector2((size.x - PAGE_SIZE.x) * 0.5, visual_top - (PAGE_SIZE.y * (1.0 - fit) * 0.5))
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
	page.draw_string(font, Vector2(140, 112), "SINGIL", HORIZONTAL_ALIGNMENT_LEFT, -1, 23, INK)
	page.draw_string(font, Vector2(350, 112), "PANGALAN / TALA", HORIZONTAL_ALIGNMENT_LEFT, -1, 23, INK)
	page.draw_string(font, Vector2(800, 112), "NATITIRA", HORIZONTAL_ALIGNMENT_LEFT, -1, 23, INK)
	var rows := [
		["01/12", "Mang Lito", "₱0", true],
		["01/18", "Mang Ramon", "₱0", true],
		["Hulugan", "Lola Rosa", "₱%d" % rosa_balance, false],
	]
	if show_paolo:
		rows.append([_due_date(6), "Paolo", "₱3", false])
	if not records.is_empty():
		rows = records
	for i in range(rows.size()):
		var row: Array = rows[i]
		var y := 155.0 + i * 48.0
		page.draw_string(HANDWRITING, Vector2(140, y), str(row[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 30, INK)
		page.draw_string(HANDWRITING, Vector2(350, y), str(row[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, 32, INK)
		page.draw_string(HANDWRITING, Vector2(800, y), str(row[2]), HORIZONTAL_ALIGNMENT_LEFT, -1, 32, INK)
		if bool(row[3]):
			page.draw_line(Vector2(135, y - 15), Vector2(930, y - 21), RED, 4.0, true)
			page.draw_string(HANDWRITING, Vector2(948, y), "BAYAD NA", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, RED)

func show_records(state: CampaignState, include_paolo: bool, rosa_paid: bool) -> void:
	state.add_debt("rosa_old", "neighbor_rosa", 320, 0, 0, {}, true)
	if rosa_paid:
		for debt in state.debts:
			if debt.id == "rosa_old": debt.balance = mini(int(debt.balance), 210)
	if include_paolo:
		state.add_debt("paolo_story", "paolo", 3, 0, 6, {}, true)
	records = [["01/12", "Mang Lito", "₱0", true], ["01/18", "Mang Ramon", "₱0", true]]
	if state.day < 4: records.clear()
	for debt in state.debts:
		if state.day < 4 and debt.id == "rosa_old": continue
		if debt.id == "paolo_story" and not include_paolo: continue
		var name: String = str(debt.customer).replace("neighbor_", "").capitalize()
		if debt.customer == "neighbor_rosa": name = "Lola Rosa"
		var date := "Hulugan" if debt.id == "rosa_old" else _due_date(int(debt.due_day))
		records.append([date, name, "₱%d" % int(debt.balance), int(debt.balance) == 0])
	if records.is_empty(): records.append(["", "Wala pang bagong utang", "", false])
	show_note(include_paolo)

func _due_date(day: int) -> String:
	if day <= 0:
		return "Walang petsa"
	var date := Time.get_date_dict_from_unix_time(FIRST_DAY_UNIX + (day - 1) * 86400)
	return "%02d/%02d" % [date.month, date.day]
