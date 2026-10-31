extends SceneTree
const Card = preload("res://scripts/briefing_card.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var card = Card.new()
	root.add_child(card)
	var summary = "TODAY'S SALES\nBenta ngayong araw: ₱593\nKabuuang pera: ₱1638\nCustomers served: 13\nCustomers left: 0\n\nDAILY GOAL\nGive 2 exact sukli: COMPLETED · Tamang Sukli medal\n\nSUKLI\nTamang sukli: 10 / 12"
	for day in range(1, 8):
		card.show_summary("DAY %d COMPLETE" % day, summary, Vector2(1920, 1080), day)
		await process_frame
		var medal = card.find_child("DailyGoalMedal", true, false)
		assert(medal != null and medal.texture != null)
		assert(medal.texture.resource_path.ends_with("day_%d.png" % day))
	card.show_summary("DAY 2 COMPLETE", "DAILY GOAL\nGive 2 exact sukli: Not completed — no penalty", Vector2(1920, 1080), 2, false)
	await process_frame
	var unearned = card.find_child("DailyGoalMedal", true, false)
	assert(unearned != null and unearned.texture.resource_path.ends_with("day_2.png"))
	assert(unearned.material is ShaderMaterial and unearned.scale == Vector2.ONE)
	print("All seven daily medals and incomplete-goal handling passed")
	quit()
