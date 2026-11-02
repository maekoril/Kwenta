extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var cases := [
		{"day": 4, "moment": 16, "day4_rain": "stay", "customer": "neighbor_lina"},
		{"day": 5, "moment": 17, "day4_dodong_seen": true, "visitor": "kuya_dodong"},
		{"day": 5, "moment": 18, "day4_rain": "join", "visitor": "neighbor_lina"},
		{"day": 6, "moment": 19, "day3_candy": "free", "customer": "classmate_1"},
		{"day": 6, "moment": 20, "day3_candy": "free", "customer": "classmate_2"},
		{"day": 6, "moment": 21, "day3_candy": "free", "customer": "classmate_3"},
		{"day": 6, "moment": 22, "day3_candy": "no", "customer": "paolo"},
	]
	for entry in cases:
		set_meta("kwenta_debug_launch", entry)
		change_scene_to_file("res://scenes/main.tscn")
		await create_timer(1.5).timeout
		var main = current_scene
		if entry.has("visitor"):
			assert(main.story_events._current.get("event", {}).get("visitor") == entry.visitor)
		else:
			assert(main.shift.active_customers.any(func(c): return c.customer_id == entry.customer) or main.shift.story_queue.any(func(c): return c.get("customer_id", "") == entry.customer))
	print("Missing story event shortcuts passed")
	quit()
