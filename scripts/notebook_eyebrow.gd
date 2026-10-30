class_name NotebookEyebrow
extends VBoxContainer

# Small, muted, all-caps label above the page header ("KUWADERNO"). It's tier 4 on purpose:
# it names where you are without competing with the header. Assigning `text` upper-cases it
# and hides the whole thing when the text is empty, so main.gd can keep doing
# `summary_speaker.text = ...` exactly as before.

var text: String = "":
	set(value):
		text = value
		_apply()

var _label: Label

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label = KwentaStyle.make_label("", KwentaStyle.SIZE_CAPTION, KwentaStyle.INK_MUTED)
	add_child(_label)
	visible = false

func _apply() -> void:
	_label.text = text.to_upper()
	visible = not text.strip_edges().is_empty()
