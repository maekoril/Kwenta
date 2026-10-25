class_name StoreConfig
extends RefCounted

static func load_config(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Missing store config: %s" % path)
		return {}
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK or not json.data is Dictionary:
		push_error("Invalid store config: %s" % path)
		return {}
	var data: Dictionary = json.data
	var base: Array = data.get("base_size", [0, 0])
	data["base_size"] = Vector2i(int(base[0]), int(base[1]))
	return data

static func get_stocked_ids(config: Dictionary, day: int, purchased_groups: Array) -> Array[String]:
	var stocked: Array[String] = []
	for entry in get_stocked_entries(config, day, purchased_groups):
		stocked.append(str(entry.get("id", "")))
	return stocked

static func get_stocked_entries(config: Dictionary, day: int, purchased_groups: Array) -> Array[Dictionary]:
	var stocked: Array[Dictionary] = []
	for product_id in config.get("products", {}):
		var entry: Dictionary = config.products[product_id]
		if entry.get("unlock_type") == "story" and day >= int(entry.get("unlock_day", 1)):
			var stocked_entry := entry.duplicate()
			stocked_entry["id"] = product_id
			stocked.append(stocked_entry)
		elif entry.get("unlock_type") == "buyable" and purchased_groups.has(str(entry.get("purchase_group", product_id))):
			var purchased_entry := entry.duplicate()
			purchased_entry["id"] = product_id
			stocked.append(purchased_entry)
	return stocked
