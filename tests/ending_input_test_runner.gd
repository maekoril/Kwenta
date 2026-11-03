extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.debug_session = true
	main.campaign.day = 7
	var product = main.product_items_by_id.values()[0]
	product.drag_enabled = true
	product._begin_drag(Vector2(500, 500), -1)
	assert(product._drag_active)
	main.story_beats.assign([{"cutscene": "day7_walk", "speaker": "Narrator", "text": "School montage finished."}])
	main.story_beat_index = 0
	main._show_current_story_beat()
	assert(not product._drag_active)
	assert(main.product_layer.mouse_behavior_recursive == Control.MOUSE_BEHAVIOR_DISABLED)
	assert(main.customer_layer.mouse_behavior_recursive == Control.MOUSE_BEHAVIOR_DISABLED)
	for index in range(4):
		await create_timer(0.7).timeout
		var point: Vector2 = product.get_global_rect().get_center()
		var press := InputEventMouseButton.new()
		press.position = point
		press.global_position = point
		press.button_index = MOUSE_BUTTON_LEFT
		press.pressed = true
		root.push_input(press, true)
		var touch := InputEventScreenTouch.new()
		touch.position = point
		touch.index = 0
		touch.pressed = true
		root.push_input(touch, true)
		await process_frame
		assert(not product._drag_active)
		assert(not product.is_processing_input())
		press.pressed = false
		touch.pressed = false
		root.push_input(press, true)
		root.push_input(touch, true)
	assert(main.story_illustration.texture.resource_path.ends_with("day7_classroom_turn.png"))
	main.queue_free()
	await process_frame
	var credits = load("res://scripts/credits.gd").new()
	root.add_child(credits)
	await process_frame
	var requested := [false]
	credits.campaign_board_requested.connect(func(): requested[0] = true)
	var button: Button = credits.stage.get_node("ViewCampaignBoardButton")
	assert(button.text == "View Campaign Board")
	button.pressed.emit()
	assert(requested[0])
	await process_frame
	assert(not is_instance_valid(credits))
	print("School montage blocks mouse/touch pickup and cancels held drags; credits board action: PASS")
	quit()
