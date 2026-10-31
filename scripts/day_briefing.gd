class_name DayBriefing
extends RefCounted

var heading: String
var change_lines: Array[String] = []
var goal_title: String
var goal_reward: String
var eyebrow: String
var title: String
var focus: String
var shift_detail: String
var product_section_title: String = ""
var unlocked_product_names: Array[String] = []
var unlocked_products: Array[ProductData] = []

func _init(day: int, goal, products: Array = [], store_config: Dictionary = {}, new_purchase_groups: Array = []) -> void:
	heading = "DAY %d" % day
	change_lines = _change_lines(day)
	goal_title = str(goal.title)
	goal_reward = str(goal.reward)
	eyebrow = "WELCOME TO KWENTA" if day == 1 else "TODAY'S NEW CHALLENGE"
	title = heading
	focus = change_lines[0]
	shift_detail = change_lines[1] if change_lines.size() > 1 else ""
	var new_product_ids: Array[String] = []
	if not store_config.is_empty():
		for entry_value in store_config.get("products", {}).values():
			var entry: Dictionary = entry_value
			var is_story_unlock: bool = entry.get("unlock_type") == "story" and int(entry.get("unlock_day", 1)) == day
			var is_new_purchase: bool = entry.get("unlock_type") == "buyable" and new_purchase_groups.has(str(entry.get("purchase_group", "")))
			var product_id := str(entry.get("game_product_id", ""))
			if (is_story_unlock or is_new_purchase) and not product_id.is_empty() and not new_product_ids.has(product_id):
				new_product_ids.append(product_id)
	for product_value in products:
		if product_value is ProductData and (new_product_ids.has(product_value.id) if not store_config.is_empty() else product_value.unlock_day == day) and not product_value.display_name.is_empty() and not unlocked_products.has(product_value):
			unlocked_product_names.append(product_value.display_name)
			unlocked_products.append(product_value)
	if not unlocked_product_names.is_empty():
		product_section_title = "STARTING SHELF" if day == 1 else "NEW ON THE SHELF"

func panel_text() -> String:
	var sections: Array[String] = ["TODAY'S FOCUS\n%s" % focus]
	if not product_section_title.is_empty():
		sections.append("%s\n%s" % [product_section_title, " · ".join(unlocked_product_names)])
	if not shift_detail.is_empty():
		sections.append("SHIFT DETAILS\n%s" % shift_detail)
	sections.append("OPTIONAL DAILY GOAL\n%s\nReward — %s" % [goal_title, goal_reward])
	return "\n\n".join(sections)

func notebook_title() -> String:
	return "YOUR FIRST SHIFT · DAY 1" if title == "YOUR FIRST SHIFT" else heading

func _day_name(day: int) -> String:
	match day:
		1: return "UNANG ARAW"
		2: return "SUKLI"
		3: return "DAGDAG-ORDER"
		4: return "ULAN"
		5: return "SUKI"
		6: return "PIYESTA"
		_: return "HULING ARAW"

func _change_lines(day: int) -> Array[String]:
	match day:
		1: return ["Drag products to serve each order.", "Shift ends at 12:00 PM"]
		2: return ["Give the correct sukli after each sale.", "Shift ends at 5:00 PM"]
		3: return ["Practice orders with different products as customers overlap.", "Shift ends at 6:00 PM"]
		4: return ["Rain makes customers less patient", "Shift ends at 6:00 PM"]
		5: return ["Regulars matter during the rush.", "Shift ends at 8:00 PM"]
		6: return ["Fiesta rush: more customers at once.", "A brownout arrives mid-shift"]
		_: return ["Final day: customers will not lose trust.", "Shift ends at 8:00 PM"]
