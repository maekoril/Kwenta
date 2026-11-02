extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.bubble.close()
	await create_timer(0.3).timeout
	main.campaign.day = 1
	main.completed_tutorials.clear()
	main.story_events._visitor_tutorial_seen = false
	main._rebuild_product_shelf()
	main.shift_in_progress = true
	main.tutorial_delivery_seen = false
	main._after_opening_sign()
	assert(main.shift.get_active_customers().is_empty())
	assert(main.story_events._mode == "visitor")
	assert(main.shift.frozen)
	await create_timer(0.7).timeout
	var visitor = main.story_events.find_child("StoryVisitorButton", true, false)
	assert(visitor != null)
	assert(main.story_events.find_child("StoryVisitorTutorial", true, false) != null)
	visitor.pressed.emit()
	for i in range(5): main.bubble.advanced.emit()
	await create_timer(0.4).timeout
	assert(main.shift.get_active_customers().size() == 1)
	assert(main.shift.get_active_customers()[0].customer_id == "aling_nena")
	for i in range(2): main.bubble.advanced.emit()
	await create_timer(0.7).timeout
	assert(main.tutorial_step == main.TutorialStep.DAY1_PRODUCT)
	assert(not main.tutorial_overlay.arrow_visible)
	var elapsed: float = main.shift.elapsed_seconds
	main._process(1.0)
	assert(main.shift.elapsed_seconds == elapsed)
	var product = main.product_items_by_id[main.tutorial_product_id]
	var product_id: String = main.tutorial_product_id
	product._begin_drag(product.get_global_rect().get_center(), -1)
	assert(main.tutorial_step == main.TutorialStep.DAY1_CUSTOMER)
	assert(main.tutorial_overlay.arrow_visible)
	product._release_drag(Vector2(-100, -100))
	assert(main.tutorial_step == main.TutorialStep.DAY1_PRODUCT)
	assert(not main.tutorial_overlay.arrow_visible)
	await create_timer(0.4).timeout
	product._begin_drag(product.get_global_rect().get_center(), -1)
	assert(main.tutorial_step == main.TutorialStep.DAY1_CUSTOMER)
	assert(main._resolve_product_delivery(main.tutorial_customer_id, product_id))
	product.finish_drag(true)
	assert(main.tutorial_delivery_seen)
	assert(main.tutorial_step == main.TutorialStep.NONE)
	assert(main.completed_tutorials.get("story_event", false))
	print("PASS: Berting before Nena; pickup, drag, missed-drop reset, retry, successful delivery; paused tutorial clock.")
	quit()
