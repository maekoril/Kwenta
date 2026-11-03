extends ReferenceRect

func _ready() -> void:
	name = "SelectionOutline"
	editor_only = false
	border_color = KwentaStyle.INK
	border_width = 2.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	offset_left = 9
	offset_top = 9
	offset_right = -9
	offset_bottom = -9
