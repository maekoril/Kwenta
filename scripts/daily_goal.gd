class_name DailyGoal
extends RefCounted

enum Type { CUSTOMERS_SERVED, EXACT_CHANGE, MULTI_ITEM_ORDERS, NO_TIMEOUTS, TRUSTED_REGULARS }

var type: int
var title: String
var reward: String
var target: int
var current := 0
var timed_out := false

func _init(day: int) -> void:
	match day:
		1:
			_setup(Type.CUSTOMERS_SERVED, "Serve 3 customers", "First Shift sticker", 3)
		2:
			_setup(Type.EXACT_CHANGE, "Give 2 exact sukli", "Coin-doodle sticker", 2)
		3:
			_setup(Type.MULTI_ITEM_ORDERS, "Finish 3 multi-item orders", "Neat shelf-label detail", 3)
		4:
			_setup(Type.NO_TIMEOUTS, "Let no customer leave", "Rainy-day thank-you note", 1)
		5:
			_setup(Type.CUSTOMERS_SERVED, "Serve 4 customers", "Suki notebook sticker", 4)
		6:
			_setup(Type.CUSTOMERS_SERVED, "Serve 10 Fiesta customers", "Fiesta bunting decoration", 10)
		_:
			_setup(Type.TRUSTED_REGULARS, "Finish with 3 trusted regulars", "Final notebook decoration", 3)

func _setup(goal_type: int, goal_title: String, goal_reward: String, goal_target: int) -> void:
	type = goal_type
	title = goal_title
	reward = goal_reward
	target = goal_target

func record_customer_served(order_units: int) -> void:
	if type == Type.CUSTOMERS_SERVED:
		current = mini(target, current + 1)
	elif type == Type.MULTI_ITEM_ORDERS and order_units > 1:
		current = mini(target, current + 1)

func record_exact_change() -> void:
	if type == Type.EXACT_CHANGE:
		current = mini(target, current + 1)

func record_timeout() -> void:
	if type == Type.NO_TIMEOUTS:
		timed_out = true

func finalize(trusted_regulars: int) -> void:
	if type == Type.NO_TIMEOUTS and not timed_out:
		current = target
	elif type == Type.TRUSTED_REGULARS:
		current = mini(target, trusted_regulars)

func is_complete() -> bool:
	return current >= target

func is_no_timeout_goal() -> bool:
	return type == Type.NO_TIMEOUTS

func progress_text() -> String:
	if type == Type.NO_TIMEOUTS:
		return "FAILED" if timed_out else "IN PROGRESS"
	return "%d / %d" % [current, target]
