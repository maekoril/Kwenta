extends SceneTree

var completed := 0
var closing_count := 0

func _initialize() -> void:
	var config = load("res://data/story/summer_campaign.tres")
	assert(config.get_customer_spawn_interval_for_day(1) == 11.0)
	var manager = ShiftManager.new(CampaignState.new(config), {}, RandomNumberGenerator.new())
	manager.shift_completed.connect(func(): completed += 1)
	manager.closing_started.connect(func(): closing_count += 1)
	manager.is_running = true
	manager.shift_duration_seconds = 10.0
	manager.shift_close_minutes = 240
	var customer = CustomerState.new("test", OrderState.new({}), 50.0)
	customer.instance_id = "test_1"
	customer.begin_payment(15, 20, 20.0)
	manager.active_customers.append(customer)
	manager.elapsed_seconds = 9.0
	manager.advance_time(1.0)
	assert(manager.is_closing and manager.is_running and completed == 0 and closing_count == 1)
	var patience: float = customer.patience_remaining
	manager.advance_time(2.0)
	assert(customer.patience_remaining < patience and manager.active_customers.size() == 1)
	assert(manager.elapsed_seconds == 12.0)
	manager.give_change("test_1", 5)
	assert(completed == 1 and not manager.is_running)
	manager.advance_time(5.0)
	assert(completed == 1)
	var empty = ShiftManager.new(CampaignState.new(config), {}, RandomNumberGenerator.new())
	empty.is_running = true
	empty.shift_duration_seconds = 1.0
	empty.advance_time(1.0)
	assert(empty.did_emit_completion)
	var timeout = ShiftManager.new(CampaignState.new(config), {}, RandomNumberGenerator.new())
	timeout.is_running = true
	timeout.shift_duration_seconds = 1.0
	var waiting = CustomerState.new("waiting", OrderState.new({"instant_noodles": 1}), 2.0)
	timeout.active_customers.append(waiting)
	timeout.advance_time(1.0)
	assert(timeout.is_closing and timeout.is_running)
	timeout.advance_time(1.0)
	assert(timeout.did_emit_completion and timeout.customers_timed_out == 1)
	print("Shift closing checks passed")
	quit()
