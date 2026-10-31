extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var tray := CashTray.new()
	root.add_child(tray)
	await process_frame
	var customer := CustomerState.new("test", OrderState.new({}), 30.0)
	customer.instance_id = "test"
	customer.begin_payment(47, 50, 30.0)
	for day in range(2, 8):
		tray.open_for(customer, SukliRules.sukli_guide_enabled_for_day(day))
		await process_frame
		await process_frame
		var paper := tray._note_paper.get_global_rect()
		assert(paper.encloses(tray._bayad_label.get_global_rect()))
		assert(paper.encloses(tray._total_label.get_global_rect()))
		assert(paper.encloses(tray._list_change_row.get_global_rect()))
		assert(tray._due_label.text == "₱3" and tray._list_change_row.visible)
		assert(tray._helper_row.visible == (day == 2))
	print("Listahan rows fit on the paper for Days 2–7")
	quit()
