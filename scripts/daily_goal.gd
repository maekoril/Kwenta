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
			_setup(Type.CUSTOMERS_SERVED, "Serve 3 customers", "First Shift medal", 3)
		2:
			_setup(Type.EXACT_CHANGE, "Give 2 exact sukli", "Tamang Sukli medal", 2)
		3:
			_setup(Type.MULTI_ITEM_ORDERS, "Complete 3 orders with 2+ different products", "Maayos na Order medal", 3)
		4:
			_setup(Type.NO_TIMEOUTS, "Let no customer leave", "Tag-ulan medal", 1)
		5:
			_setup(Type.CUSTOMERS_SERVED, "Serve 4 customers", "Suki medal", 4)
		6:
			_setup(Type.CUSTOMERS_SERVED, "Serve 10 Fiesta customers", "Fiesta medal", 10)
		_:
			_setup(Type.TRUSTED_REGULARS, "Finish with 3 trusted regulars", "Mga Suki medal", 3)

func _setup(goal_type: int, goal_title: String, goal_reward: String, goal_target: int) -> void:
	type = goal_type
	title = goal_title
	reward = goal_reward
	target = goal_target

func record_customer_served(product_types: int) -> void:
	if type == Type.CUSTOMERS_SERVED:
		current = mini(target, current + 1)
	elif type == Type.MULTI_ITEM_ORDERS and product_types > 1:
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
