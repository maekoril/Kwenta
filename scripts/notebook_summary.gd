class_name NotebookSummary
extends VBoxContainer

# Turns the page's body text into a visual hierarchy, without main.gd building anything new.
# It reads the same string main.gd already sets, for example:
#
#   Tapos ang Day 2.                          <- plain line: lead paragraph
#
#   Benta ngayong araw: ₱320                  <- FIRST "label: value" line: the hero number
#   Kabuuang pera: ₱470                       <- other lines in that group: ledger rows
#
#   Tamang sukli: 4 / 5                       <- later groups (after a blank line): small stats
#   Pinakamahabang tuloy-tuloy na tama: 3
#
# Lines with no ": " (like the ending paragraph) are shown as readable body text.
# Peso amounts are green, everything else is ink.

var text: String = "":
	set(value):
		text = value
		_rebuild()

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 10)

func _rebuild() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var hero_done := false
	var groups := text.split("\n\n")
	for group_index in groups.size():
		var plain_lines: Array[String] = []
		var rows: Array[PackedStringArray] = []
		for raw_line in groups[group_index].split("\n"):
			var line := raw_line.strip_edges()
			if line.is_empty():
				continue
			var cut := line.find(": ")
			if cut > 0 and cut < line.length() - 2:
				rows.append(PackedStringArray([line.substr(0, cut), line.substr(cut + 2)]))
			else:
				plain_lines.append(line)
		if group_index > 0 and (not rows.is_empty() or not plain_lines.is_empty()):
			add_child(_rule())
		if not plain_lines.is_empty():
			add_child(_paragraph("\n".join(plain_lines)))
		for row in rows:
			if not hero_done:
				add_child(_hero(row[0], row[1]))
				hero_done = true
			elif group_index == 0:
				add_child(_row(row[0], row[1], KwentaStyle.SIZE_ROW_LABEL, KwentaStyle.SIZE_ROW_VALUE))
			else:
				add_child(_row(row[0], row[1], KwentaStyle.SIZE_SMALL, KwentaStyle.SIZE_SMALL))

func _paragraph(content: String) -> Label:
	var label := KwentaStyle.make_label(content, KwentaStyle.SIZE_BODY, KwentaStyle.INK)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_constant_override("line_spacing", 6)
	return label

# The one number that matters: small caption, then a big value.
func _hero(caption: String, value: String) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 0)
	box.add_child(KwentaStyle.make_label(caption.to_upper(), KwentaStyle.SIZE_CAPTION, KwentaStyle.INK_MUTED))
	box.add_child(KwentaStyle.make_label(value, KwentaStyle.SIZE_HERO, _value_color(value)))
	return box

# Ledger row: muted label on the left, value on the right.
func _row(caption: String, value: String, label_size: int, value_size: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label := KwentaStyle.make_label(caption, label_size, KwentaStyle.INK_MUTED)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var value_label := KwentaStyle.make_label(value, value_size, _value_color(value))
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.custom_minimum_size.x = 220.0
	row.add_child(value_label)
	return row

func _rule() -> ColorRect:
	var rule := ColorRect.new()
	rule.color = Color(KwentaStyle.INK, 0.35)
	rule.custom_minimum_size = Vector2(0.0, 2.0)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rule

func _value_color(value: String) -> Color:
	return KwentaStyle.MONEY if value.contains("₱") else KwentaStyle.INK
