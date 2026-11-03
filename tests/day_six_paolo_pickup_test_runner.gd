extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size = Vector2i(1920, 1080)
	for route in ["ask", "alone"]:
		set_meta("kwenta_debug_launch", {"day": 6, "moment": 23, "skip_tutorials": true, "day3_candy": "credit", "day6_help": route})
		change_scene_to_file("res://scenes/main.tscn")
		await create_timer(0.6).timeout
		var main = current_scene
		if main.fiesta_preview_step >= 0: main._finish_fiesta_preview()
		main.completed_tutorials['fiesta_skill_visuals'] = true
		assert(main.story_events._current.event.visitor == "paolo_repayment")
		assert(main.product_layer.mouse_behavior_recursive == Control.MOUSE_BEHAVIOR_DISABLED)
		var before: int = main.campaign.cash
		for i in range(4): main.bubble.advanced.emit()
		await create_timer(0.4).timeout
		assert(main.campaign.cash == before + 3)
		assert(not main.campaign.has_debt("paolo"))
		assert(not main.story_events.is_active() and not main.shift.frozen)
		assert(main._blocked_input_nodes.is_empty())
		assert(main.product_layer.mouse_behavior_recursive != Control.MOUSE_BEHAVIOR_DISABLED)
		var coffee: Control = main.product_items_by_id["coffee_sachet"]
		var at: Vector2 = coffee.get_global_rect().get_center()
		var motion := InputEventMouseMotion.new()
		motion.position = at
		root.push_input(motion)
		await process_frame
		var press := InputEventMouseButton.new()
		press.position = at
		press.button_index = MOUSE_BUTTON_LEFT
		press.pressed = true
		root.push_input(press)
		await process_frame
		print("Route ", route, " hovered=", root.gui_get_hovered_control(), " coffee drag=", coffee._drag_active)
		assert(coffee._drag_active, "Kapeko receives actual mouse pickup after Paolo repayment")
		# Interrupt an active pickup with the actual Paolo repayment event.
		var event: Dictionary = main.story.get_day_shift_events(6).filter(func(e): return e.get("visitor") == "paolo_repayment")[0]
		main.story_events._queue_popup({"kind": "narrative", "event": event})
		press.pressed = false
		root.push_input(press)
		for i in range(4): main.bubble.advanced.emit()
		await create_timer(0.4).timeout
		assert(not coffee.is_drag_active(), "Story interruption must cancel the custom product drag")
		press.pressed = true
		root.push_input(press)
		await process_frame
		assert(coffee._drag_active, "Kapeko can be picked up again after an interrupted drag")
		coffee.finish_drag(true)
		press.pressed = false
		root.push_input(press)
	print("PASS: Paolo repayment releases shelf input and Kapeko pickup on both fiesta routes")
	quit()

