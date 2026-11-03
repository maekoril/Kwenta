extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1920, 1080)
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.bubble.close()
	await create_timer(0.4).timeout
	main.campaign.day = 6
	main._rebuild_product_shelf()
	var coffee: Control = main.product_items_by_id["coffee_sachet"]
	for viewport_size in [Vector2i(1920, 1080), Vector2i(2400, 1080), Vector2i(1920, 1440), Vector2i(1920, 1080)]:
		root.size = viewport_size
		await process_frame
		await process_frame
		for entry in StoreConfig.get_stocked_entries(StoreConfig.load_config("res://data/store_config.json"), 6, main.campaign.purchased_store_groups):
			var item: Control = main.product_items_by_id[entry.game_product_id]
			var slot: Rect2 = main.store_layer_renderer.get_slot_rect(entry.id)
			assert(item.position.is_equal_approx(slot.position), "Pickup position must follow resized shelf")
			assert(item.size.is_equal_approx(slot.size), "Pickup size must follow resized shelf")
		var display: Rect2 = main.store_layer_renderer.get_product_display_rect("kapeko_blanca")
		assert(coffee.get_global_rect().has_point(display.get_center()))
		var press := InputEventScreenTouch.new()
		press.pressed = true
		press.index = 0
		press.position = display.get_center()
		coffee._gui_input(press)
		assert(coffee._drag_active, "Day 6 Kapeko can be picked up")
		coffee.finish_drag(true)
	main.queue_free()
	await process_frame
	print("Day 6 pickup areas follow shelf resizing; Kapeko drag starts at every tested size")
	quit()
