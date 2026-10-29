class_name NotebookTitle
extends VBoxContainer

# The page header. main.gd already builds titles like "DAY 1 COMPLETE · Ayoko Nito";
# this splits at " · " into the header (tier 1, biggest, darkest) and the day's story title
# as a smaller muted subtitle (tier 3). Titles with no separator just show the header.

const SEPARATOR := " · "

var text: String = "":
	set(value):
		text = value
		_apply()

var _main: Label
var _sub: Label

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 2)
	_main = KwentaStyle.make_label("", KwentaStyle.SIZE_H1, KwentaStyle.INK)
	_sub = KwentaStyle.make_label("", KwentaStyle.SIZE_ROW_LABEL, KwentaStyle.INK_MUTED)
	add_child(_main)
	add_child(_sub)
	_sub.visible = false

func _apply() -> void:
	var parts := text.split(SEPARATOR, true, 1)
	_main.text = parts[0] if parts.size() > 0 else ""
	var has_sub := parts.size() > 1 and not parts[1].strip_edges().is_empty()
	_sub.text = parts[1] if has_sub else ""
	_sub.visible = has_sub
