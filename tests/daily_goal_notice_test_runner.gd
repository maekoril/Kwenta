extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main._on_customer_served("a", 1)
	main._on_customer_served("b", 1)
	assert(main.find_child("DailyGoalAchievementNotice", true, false) == null)
	main._on_customer_served("c", 1)
	var notice = main.find_child("DailyGoalAchievementNotice", true, false)
	assert(notice != null and notice.find_child("AchievementMedal", true, false).texture != null)
	main._on_customer_served("d", 1)
	var count := 0
	for child in main.get_children():
		if child.name == "DailyGoalAchievementNotice": count += 1
	assert(count == 1)
	var card = main.briefing_card
	card.show_summary("DAY 1 COMPLETE", "TODAY'S SALES\nSales: ₱100\n\nDAILY GOAL COMPLETE!\nServe 3 customers", Vector2(1920, 1080), 1)
	await process_frame
	assert(card.find_child("DailyGoalMedal", true, false) != null)
	print("Daily goal notice and summary medal passed")
	quit()
