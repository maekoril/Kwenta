class_name NotebookScroll
extends ScrollContainer

var _finger_dragging := false

func supports_touch_drag() -> bool:
	return true

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_finger_dragging = event.pressed
		accept_event()
		return
	if event is InputEventScreenDrag and _finger_dragging:
		scroll_vertical = maxi(0, scroll_vertical - roundi(event.relative.y))
		accept_event()
		return
	if event is InputEventPanGesture:
		scroll_vertical = maxi(0, scroll_vertical + roundi(event.delta.y))
		accept_event()
