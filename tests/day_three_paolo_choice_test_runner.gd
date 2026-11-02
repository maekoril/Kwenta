extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	for option in ["credit", "free", "no"]:
		var main = load("res://scenes/main.tscn").instantiate()
		root.add_child(main)
		await process_frame
		main.bubble.close()
		main.campaign.day = 3
		main._rebuild_product_shelf()
		assert(main.campaign.get_available_product_ids().has("soft_drink"))
		assert(main.campaign.get_product_price(main.products_by_id["soft_drink"]) == 15)
		main.story_events.begin_shift(3)
		main.shift.is_running = true
		var events: Array = main.story.get_day_shift_events(3)
		var paolo: Dictionary = events.filter(func(event): return event.get("visitor") == "paolo")[0]
		assert(paolo.beats.any(func(beat): return beat.get("show_prop") == "paolo_coins"))
		assert(paolo.choice.prompt.contains("Coke"))
		assert(main.story.get_day_outro_beats(3).any(func(beat): return beat.get("cutscene") == "day3_project"))
		var selected_option: Dictionary = paolo.choice.options.filter(func(entry): return entry.id == option)[0]
		var thanks: Array = selected_option.response.filter(func(beat): return beat.get("speaker") == "Paolo" and str(beat.get("text", "")).contains("Salamat"))
		assert(not thanks.is_empty() if option != "no" else thanks.is_empty())
		assert(main.paolo_debt_note.z_index + main.paolo_debt_note.page.z_index > main.bubble.z_index)
		var before: int = main.campaign.cash
		main.story_events._queue_popup({"kind": "scene", "event": paolo})
		await create_timer(0.7).timeout
		main.story_events.find_child("StoryVisitorButton", true, false).pressed.emit()
		while main.story_events._mode == "beats":
			main.bubble.advanced.emit()
		assert(main.story_events._mode == "choice")
		main.bubble.choice_made.emit(["credit", "free", "no"].find(option))
		var expected: int = before if option == "no" else before + 12
		assert(main.campaign.cash == expected)
		assert(main.shift.shift_earnings == (0 if option == "no" else 12))
		assert(main.shift.customers_served == (0 if option == "no" else 1))
		assert(main.story.get_choice("day3_candy") == option)
		var saw_note := false
		while main.story_events._mode == "beats":
			saw_note = saw_note or main.paolo_debt_note.visible
			main.bubble.advanced.emit()
		assert(not saw_note)
		assert(not main.paolo_debt_note.visible)
		var later: Array = main.story.get_day_callback_beats(6)
		var repayment: Array = later.filter(func(beat): return str(beat.get("debt_payment", "")) == "paolo_story")
		assert(repayment.size() == (1 if option == "credit" else 0))
		main.queue_free()
		await process_frame
	print("Paolo Coke price, three choices, cash and repayment checks passed")
	quit()
