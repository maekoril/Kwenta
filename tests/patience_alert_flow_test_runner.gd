extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.bubble.close()
	var first := CustomerState.new("bea", OrderState.new({"biscuits": 1}), 100.0)
	first.instance_id = "bea_test"
	var second := CustomerState.new("paolo", OrderState.new({"biscuits": 1}), 100.0)
	second.instance_id = "paolo_test"
	main.shift.active_customers.append(first)
	main.shift.active_customers.append(second)
	main._rebuild_customer_slots()
	await process_frame
	var a = main.customer_actors[first.instance_id]
	var b = main.customer_actors[second.instance_id]
	assert(main.audio._alert_player.bus == "SFX")
	first.patience_remaining = 29.0
	a.refresh_patience()
	assert(main.audio._alert_wanted and main.audio._alert_player.playing)
	first.begin_payment(10, 20, 100)
	a.refresh_patience()
	assert(not main.audio._alert_wanted)
	first.patience_remaining = 29.0
	a.refresh_patience()
	assert(main.audio._alert_wanted and main.angry_customer_ids.has(first.instance_id))
	second.patience_remaining = 29.0
	b.refresh_patience()
	first.active = false
	main.shift.active_customers.erase(first)
	main._rebuild_customer_slots()
	assert(main.audio._alert_wanted and main.angry_customer_ids.has(second.instance_id))
	second.active = false
	main.shift.active_customers.erase(second)
	main._rebuild_customer_slots()
	assert(not main.audio._alert_wanted and not main.audio._alert_player.playing)
	AudioSettings.set_volume("SFX", 0.0)
	assert(AudioServer.is_bus_mute(AudioServer.get_bus_index(main.audio._alert_player.bus)))
	AudioSettings.set_volume("SFX", 1.0)
	main.queue_free()
	print("Low-patience alert follows SFX bus in ordering and sukli, and stops after the last customer")
	quit()
