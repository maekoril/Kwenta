extends RefCounted

# Shared marker for story visitors and customers who also have a story scene.
static func create_marker() -> Label:
	var marker := KwentaStyle.make_label("!", 90, Color("ffb43c"))
	marker.name = "StoryEventMarker"
	marker.add_theme_color_override("font_outline_color", Color("46230e"))
	marker.add_theme_constant_override("outline_size", 8)
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return marker
