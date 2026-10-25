extends SceneTree
const Renderer = preload("res://scripts/store_layer_renderer.gd")
var failures := 0
func _initialize() -> void:
	var renderer := Renderer.new()
	root.add_child(renderer)
	await process_frame
	renderer.configure(1, 150)
	_assert(renderer.get_node_or_null("EmptyBackground") != null and renderer.get_node_or_null("FrontBackground") != null, "renderer creates both background layers")
	_assert(renderer.get_node("EmptyBackground").z_index < renderer.get_node("FrontBackground").z_index, "front art draws over customer layer")
	_assert(renderer.get_slot_rect("feeta").size.x > 0.0, "slot data exposes scaled tap bounds")
	_assert(renderer.get_node_or_null("Slots/feeta") != null, "stocked sticker has a tap target")
	_assert(renderer.get_node_or_null("Slots/feeta_product") != null, "stocked Day 1 product is rendered")
	_assert(renderer.get_node_or_null("Slots/zesty_product") == null, "locked story products stay empty instead of showing a product")
	_assert(renderer.get_node_or_null("Slots/zesty_lock") == null, "locked story products stay empty instead of showing a lock")
	_assert(renderer.get_node_or_null("Slots/bato_spring_water_lock") != null, "buyable stock shows one named lock")
	_assert(renderer.get_node_or_null("Slots/condiments_lock") != null, "condiment trio shares one lock")
	_assert(renderer.get_node_or_null("Slots/pating_lock") == null and renderer.get_node_or_null("Slots/real_suka_lock") == null, "condiment group does not duplicate locks")
	var water_lock := renderer.get_node_or_null("Slots/bato_spring_water_lock")
	_assert(water_lock != null and water_lock.get_node("LockLabel").text == "DAY 2", "future buyable lock states show its day")
	renderer.configure(2, 300)
	water_lock = renderer.get_node_or_null("Slots/bato_spring_water_lock")
	_assert(water_lock != null and water_lock.get_node("LockLabel").text == "₱250", "available buyable lock states show its price")
	renderer.queue_free()
	if failures > 0: quit(1)
	quit(0)
func _assert(ok: bool, message: String) -> void:
	if not ok: failures += 1; push_error(message)
