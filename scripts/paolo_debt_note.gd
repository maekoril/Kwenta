extends Control

# A brief story illustration, not an interactive debt ledger.
const HANDWRITING: Font = preload("res://assets/fonts/Caveat.ttf")
const PAGE_SIZE := Vector2(900.0, 440.0)
var page: PanelContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 44
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0.06, 0.035, 0.02, 0.48)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	page = PanelContainer.new()
	page.name = "PaoloDebtPage"
	# Keep the paper above the dialogue's dimmer while its own backdrop stays below it.
	page.z_index = 7
	page.size = PAGE_SIZE
	page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := KwentaStyle.box(KwentaStyle.PAPER, KwentaStyle.INK, 56.0, 36.0, 12, 5, 10)
	style.content_margin_left = 100.0
	page.add_theme_stylebox_override("panel", style)
	add_child(page)
	var paper := NotebookPaper.new()
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(paper)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(column)
	var caption := KwentaStyle.make_label("KUWADERNO · UTANG", 26, KwentaStyle.INK_MUTED)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(caption)
	for entry in [["Paolo", 68], ["Feeta  ·  ₱15", 48], ["Bayad  ·  ₱12", 48], ["Utang  ·  ₱3", 60]]:
		var line := KwentaStyle.make_label(entry[0], entry[1], Color("344965"))
		line.add_theme_font_override("font", HANDWRITING)
		line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(line)
	resized.connect(_layout_page)
	_layout_page()

func _layout_page() -> void:
	if not is_instance_valid(page):
		return
	var fit := minf(1.0, minf((size.x - 80.0) / PAGE_SIZE.x, (size.y - 80.0) / PAGE_SIZE.y))
	page.pivot_offset = PAGE_SIZE * 0.5
	page.position = Vector2((size.x - PAGE_SIZE.x) * 0.5, maxf(40.0, (size.y - PAGE_SIZE.y) * 0.3))
	page.scale = Vector2.ONE * maxf(0.1, fit)

func show_note() -> void:
	visible = true
	_layout_page()
